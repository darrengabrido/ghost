import Foundation
import Speech

protocol SpeechRecognizer {
    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error>
    func stop()
}

/// Default speech-to-text using Apple's on-device `Speech` framework.
/// Swap for a server-based provider by implementing `SpeechRecognizer`
/// against that provider's streaming API instead.
///
/// Deliberately **not** `@MainActor`. `AVAudioEngine`'s tap block and
/// `SFSpeechRecognizer`'s result handler are invoked by the system on
/// its own background/real-time threads, never on the main queue. If
/// this type were `@MainActor`, Swift would infer those closures as
/// MainActor-isolated (since they're plain, non-`@Sendable` closures
/// written inside a MainActor method) and assume they always run on
/// the main queue — which is false. That false assumption is what
/// produced the "BUG IN CLIENT OF LIBDISPATCH: Block was expected to
/// execute on queue ..." crash: the runtime asserts it's on the main
/// queue right as CoreAudio/Speech invoke the callback on a different
/// thread. Everything here only touches the (thread-safe)
/// `AsyncThrowingStream.Continuation` and its own lock-protected state,
/// so no actor isolation is needed — callers consume the resulting
/// stream from whichever actor they like.
///
/// `@unchecked Sendable` because it's a plain (non-actor) reference type
/// whose only mutable state (`request`, `recognitionTask`) is guarded by
/// `stateLock` — the compiler can't verify that itself, but it's true by
/// construction here.
final class SFSpeechRecognizerAdapter: NSObject, SpeechRecognizer, @unchecked Sendable {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private let stateLock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await requestAuthorizationIfNeeded()
                } catch {
                    continuation.finish(throwing: error)
                    return
                }

                let request = SFSpeechAudioBufferRecognitionRequest()
                request.shouldReportPartialResults = true
                stateLock.withLock { self.request = request }

                let inputNode = audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                // Runs on CoreAudio's real-time render thread, not the main
                // queue — only touch thread-safe/local state in here.
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    request.append(buffer)
                    let levels = VoiceActivityDetector.amplitudeLevels(from: buffer)
                    continuation.yield(.amplitude(levels))
                }

                do {
                    audioEngine.prepare()
                    try audioEngine.start()
                } catch {
                    continuation.finish(throwing: error)
                    return
                }

                // Runs on an internal Speech-framework queue, not the main
                // queue — only touch thread-safe/local state in here.
                let task = recognizer?.recognitionTask(with: request) { result, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let result else { return }

                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        continuation.yield(.finalTranscript(text))
                        continuation.finish()
                    } else {
                        continuation.yield(.partialTranscript(text))
                    }
                }
                stateLock.withLock { self.recognitionTask = task }

                continuation.onTermination = { [weak self] _ in
                    self?.stop()
                }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
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
            throw VoiceError.speechRecognitionDenied
        }
    }
}

enum VoiceError: LocalizedError {
    case speechRecognitionDenied
    case microphoneDenied

    var errorDescription: String? {
        switch self {
        case .speechRecognitionDenied:
            "Ghost needs speech recognition access to hear you."
        case .microphoneDenied:
            "Ghost needs microphone access to hear you."
        }
    }
}
