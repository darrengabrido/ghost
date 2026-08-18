@testable import Ghost
import AVFoundation

/// Scripted `TranscriptionProvider` for exercising `TranscriptionService`
/// logic without a real speech-to-text engine. Ignores the audio it's
/// given and simply replays `eventsToEmit`.
final class MockTranscriptionProvider: TranscriptionProvider, @unchecked Sendable {
    var eventsToEmit: [RawTranscriptEvent] = [.final("test utterance")]

    func transcribe(
        _ audio: AsyncThrowingStream<AVAudioPCMBuffer, Error>
    ) -> AsyncThrowingStream<RawTranscriptEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in eventsToEmit {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}
