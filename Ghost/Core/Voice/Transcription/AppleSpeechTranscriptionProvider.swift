import AVFoundation
import Speech

/// Speech-to-text via Apple's on-device `Speech` framework. Streams
/// `.partial` results as audio arrives and a `.final` result once the
/// framework detects end of speech — this is Ghost's default provider, but
/// any other `TranscriptionProvider` (a server-based API, Whisper, ...)
/// drops in without changes elsewhere.
///
/// Deliberately **not** `@MainActor`: `SFSpeechRecognizer`'s result
/// handler is invoked by the framework on its own internal queue, not
/// necessarily the main queue. If this type were `@MainActor`, Swift would
/// infer that closure as MainActor-isolated and assume it always runs on
/// the main queue — which is false, and would trigger a "BUG IN CLIENT OF
/// LIBDISPATCH" crash the moment the framework invokes it off-main.
/// Everything here only touches thread-safe state (the stream continuation,
/// and `request`/`recognitionTask` behind `stateLock`), so no actor
/// isolation is needed.
///
/// `@unchecked Sendable` because its mutable state (`request`,
/// `recognitionTask`) is guarded by `stateLock` — the compiler can't verify
/// that itself, but it's true by construction here.
final class AppleSpeechTranscriptionProvider: TranscriptionProvider, @unchecked Sendable {
    private let recognizer: SFSpeechRecognizer?
    private let stateLock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    func transcribe(
        _ audio: AsyncThrowingStream<AVAudioPCMBuffer, Error>
    ) -> AsyncThrowingStream<RawTranscriptEvent, Error> {
        AsyncThrowingStream { continuation in
            let feedTask = Task {
                do {
                    try await requestAuthorizationIfNeeded()
                } catch {
                    continuation.finish(throwing: error)
                    return
                }

                guard let recognizer, recognizer.isAvailable else {
                    continuation.finish(throwing: TranscriptionError.recognizerUnavailable)
                    return
                }

                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                stateLock.withLock { self.request = request }

                // Runs on an internal Speech-framework queue, not
                // necessarily the main queue — only touch thread-safe
                // state (the continuation) here.
                let task = recognizer.recognitionTask(with: request) { result, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let result else { return }

                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        continuation.yield(.final(text))
                        continuation.finish()
                    } else {
                        continuation.yield(.partial(text))
                    }
                }
                stateLock.withLock { self.recognitionTask = task }

                do {
                    for try await buffer in audio {
                        request.append(buffer)
                    }
                    request.endAudio()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { [weak self] _ in
                feedTask.cancel()
                self?.stopSession()
            }
        }
    }

    private func stopSession() {
        stateLock.withLock {
            request?.endAudio()
            recognitionTask?.cancel()
            request = nil
            recognitionTask = nil
        }
    }

    private func requestAuthorizationIfNeeded() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else {
            throw TranscriptionError.speechRecognitionDenied
        }
    }
}

enum TranscriptionError: LocalizedError {
    case speechRecognitionDenied
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .speechRecognitionDenied:
            "Ghost needs speech recognition access to transcribe you."
        case .recognizerUnavailable:
            "Speech recognition isn't available right now."
        }
    }
}
