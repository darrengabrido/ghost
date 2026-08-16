@testable import Ghost
import Testing

@MainActor
struct VoiceEngineTests {
    @Test
    func startListeningForwardsRecognizerEvents() async throws {
        let recognizer = MockSpeechRecognizer()
        recognizer.eventsToEmit = [
            .partialTranscript("hel"),
            .partialTranscript("hello"),
            .finalTranscript("hello")
        ]
        let engine = DefaultVoiceEngine(
            recognizer: recognizer,
            synthesizer: NoOpSpeechSynthesizer(),
            audioSession: AudioSessionManager()
        )

        var received: [VoiceEvent] = []
        for try await event in engine.startListening() {
            received.append(event)
        }

        #expect(received.count == 3)
        if case .finalTranscript(let text) = received.last {
            #expect(text == "hello")
        } else {
            Issue.record("Expected a final transcript as the last event")
        }
    }

    @Test
    func stopListeningStopsTheRecognizer() {
        let recognizer = MockSpeechRecognizer()
        let engine = DefaultVoiceEngine(
            recognizer: recognizer,
            synthesizer: NoOpSpeechSynthesizer(),
            audioSession: AudioSessionManager()
        )

        engine.stopListening()

        #expect(recognizer.stopCallCount == 1)
    }
}

@MainActor
private final class NoOpSpeechSynthesizer: SpeechSynthesizer {
    func speak(_ text: String) async throws {}
    func stopSpeaking() {}
}
