import Foundation

/// Scripted `AIConversationService` for SwiftUI previews — echoes a fixed
/// reply token-by-token to exercise the streaming UI without a network
/// call.
struct MockAIConversationService: AIConversationService {
    var reply = "I'm here. Tell me more."

    func streamResponse(to messages: [Message]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for word in reply.split(separator: " ") {
                    continuation.yield("\(word) ")
                    try? await Task.sleep(for: .milliseconds(60))
                }
                continuation.finish()
            }
        }
    }
}
