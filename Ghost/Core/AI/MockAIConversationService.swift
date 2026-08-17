import Foundation

/// Scripted `AIConversationService` for SwiftUI previews — echoes a fixed
/// reply token-by-token to exercise the streaming UI without a network
/// call.
struct MockAIConversationService: AIConversationService {
    var reply = "I'm here. Tell me more."
    /// Lets tests observe what `healthContext` a call site passed through.
    var onRequest: ((_ healthContext: String?) -> Void)?

    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error> {
        onRequest?(healthContext)
        return AsyncThrowingStream { continuation in
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
