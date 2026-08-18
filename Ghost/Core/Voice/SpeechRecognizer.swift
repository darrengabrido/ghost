import Foundation

protocol SpeechRecognizer {
    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error>
    func stop()
}

/// Bridges Ghost's transcription pipeline (`Core/Voice/Transcription`) —
/// audio capture, speech-to-text, and text cleanup — into the `VoiceEvent`
/// shape `VoiceEngine` expects, and forwards captured audio levels as
/// `.amplitude` events for the waveform.
///
/// The pipeline itself is swappable independent of this adapter: pass a
/// different `TranscriptionService` (or leave the default, which composes
/// `MicrophoneAudioCapture` + `AppleSpeechTranscriptionProvider`) to
/// change how Ghost listens or which speech-to-text engine it uses.
/// Nothing else in the app — `VoiceEngine`, `ConversationViewModel` — needs
/// to know that changed.
final class SFSpeechRecognizerAdapter: SpeechRecognizer, Sendable {
    private let transcriptionService: any TranscriptionService

    init(
        transcriptionService: (any TranscriptionService)? = nil,
        locale: Locale = Locale(identifier: "en-US")
    ) {
        self.transcriptionService = transcriptionService ?? DefaultTranscriptionService(
            audioCapture: MicrophoneAudioCapture(),
            provider: AppleSpeechTranscriptionProvider(locale: locale)
        )
    }

    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let events = transcriptionService.startTranscribing(onLevel: { levels in
                        continuation.yield(.amplitude(levels))
                    })
                    for try await event in events {
                        switch event {
                        case .partial(let text):
                            continuation.yield(.partialTranscript(text))
                        case .final(let text):
                            continuation.yield(.finalTranscript(text))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func stop() {
        transcriptionService.stop()
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
