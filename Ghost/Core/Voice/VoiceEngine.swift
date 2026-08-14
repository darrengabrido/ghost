import Foundation

/// Everything the Conversation feature needs from "voice" — recognition,
/// synthesis, and live amplitude for the waveform — behind one protocol so
/// ViewModels don't need to know which speech APIs or providers back it.
enum VoiceEvent: Sendable {
    case partialTranscript(String)
    case finalTranscript(String)
    case amplitude([CGFloat])
}

@MainActor
protocol VoiceEngine {
    /// Begins listening and returns a stream of transcript/amplitude
    /// events. The stream finishes after a `finalTranscript` event or when
    /// cancelled.
    func startListening() -> AsyncThrowingStream<VoiceEvent, Error>

    /// Stops listening immediately, cancelling any in-flight recognition.
    func stopListening()

    /// Speaks the given text, suspending until playback finishes.
    func speak(_ text: String) async throws
}

/// Default production implementation, composed from `SpeechRecognizer` +
/// `SpeechSynthesizer` + `AudioSessionManager`. Fill in provider-specific
/// behavior (on-device vs. server-based STT/TTS) by swapping those pieces,
/// not this type.
@MainActor
final class DefaultVoiceEngine: VoiceEngine {
    private let recognizer: SpeechRecognizer
    private let synthesizer: SpeechSynthesizer
    private let audioSession: AudioSessionManager

    init(
        recognizer: SpeechRecognizer = SFSpeechRecognizerAdapter(),
        synthesizer: SpeechSynthesizer = AVSpeechSynthesizerAdapter(),
        audioSession: AudioSessionManager = AudioSessionManager()
    ) {
        self.recognizer = recognizer
        self.synthesizer = synthesizer
        self.audioSession = audioSession
    }

    func startListening() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try audioSession.activate(for: .record)
                    for try await event in recognizer.recognitionEvents() {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func stopListening() {
        recognizer.stop()
        audioSession.deactivate()
    }

    func speak(_ text: String) async throws {
        try audioSession.activate(for: .playback)
        defer { audioSession.deactivate() }
        try await synthesizer.speak(text)
    }
}
