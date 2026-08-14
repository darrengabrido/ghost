import Foundation

/// Turns the app's `Message` history into whatever shape a given AI
/// provider's API expects. Kept separate from `AIConversationService` so
/// prompt/persona tuning doesn't require touching networking code.
enum PromptBuilder {
    static let systemPrompt = """
    You are Ghost, a voice-first AI companion. You speak concisely and \
    naturally, the way someone would in conversation — not in bullet \
    points or long paragraphs, since your replies are spoken aloud.
    """

    struct ChatTurn {
        let role: String
        let content: String
    }

    static func chatTurns(from messages: [Message]) -> [ChatTurn] {
        [ChatTurn(role: "system", content: systemPrompt)] + messages.map { message in
            ChatTurn(role: message.speaker == .user ? "user" : "assistant", content: message.text)
        }
    }
}
