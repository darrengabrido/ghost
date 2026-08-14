import Foundation
import Speech

@MainActor
protocol SpeechRecognizer {
    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error>
    func stop()
}

/// Default speech-to-text using Apple's on-device `Speech` framework.
/// Swap for a server-based provider by implementing `SpeechRecognizer`
/// against that provider's streaming API instead.
@MainActor
final class SFSpeechRecognizerAdapter: NSObject, SpeechRecognizer {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
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
                self.request = request

                let inputNode = audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
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

                recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
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

                continuation.onTermination = { [weak self] _ in
                    Task { @MainActor in self?.stop() }
                }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
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
