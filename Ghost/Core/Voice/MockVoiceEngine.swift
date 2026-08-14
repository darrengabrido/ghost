import Foundation

/// Scripted `VoiceEngine` for SwiftUI previews — no microphone or speech
/// framework involved.
@MainActor
final class MockVoiceEngine: VoiceEngine {
    func startListening() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.partialTranscript("Hello Ghost"))
            continuation.yield(.finalTranscript("Hello Ghost"))
            continuation.finish()
        }
    }

    func stopListening() {}

    func speak(_ text: String) async throws {}
}
