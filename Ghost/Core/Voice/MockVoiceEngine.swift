import Foundation

/// Scripted `VoiceEngine` for SwiftUI previews and tests — no microphone
/// or speech framework involved.
@MainActor
final class MockVoiceEngine: VoiceEngine {
    private(set) var stopSpeakingCallCount = 0
    private var speakContinuation: CheckedContinuation<Void, Error>?
    var holdSpeakUntilStopped = false

    func startListening() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.partialTranscript("Hello Ghost"))
            continuation.yield(.finalTranscript("Hello Ghost"))
            continuation.finish()
        }
    }

    func stopListening() {}

    func speak(_ text: String) async throws {
        guard holdSpeakUntilStopped else { return }
        try await withCheckedThrowingContinuation { continuation in
            speakContinuation = continuation
        }
    }

    func stopSpeaking() {
        stopSpeakingCallCount += 1
        speakContinuation?.resume()
        speakContinuation = nil
    }
}
