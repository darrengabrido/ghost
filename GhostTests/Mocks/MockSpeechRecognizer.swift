@testable import Ghost

/// Scripted `SpeechRecognizer` for exercising `VoiceEngine`/ViewModel
/// logic without touching `Speech`/`AVAudioEngine`. Not `@MainActor` —
/// matches `SpeechRecognizer`, which is deliberately unisolated since
/// real implementations receive callbacks off the main queue.
final class MockSpeechRecognizer: SpeechRecognizer {
    var eventsToEmit: [VoiceEvent] = [.finalTranscript("test utterance")]
    private(set) var stopCallCount = 0

    func recognitionEvents() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in eventsToEmit {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }

    func stop() {
        stopCallCount += 1
    }
}
