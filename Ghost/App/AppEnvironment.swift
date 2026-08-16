import Foundation

/// Composition root. Constructs the concrete implementation of every
/// `Core` protocol once, at launch, and hands protocol-typed references
/// down to feature ViewModels via plain initializers — no DI framework.
///
/// Swapping a voice or AI provider means changing the implementation
/// constructed here (and adding a new adapter under `Core/`); nothing
/// downstream needs to know.
@MainActor
struct AppEnvironment {
    let voiceEngine: VoiceEngine
    let aiConversationService: AIConversationService
    let conversationStore: ConversationStore

    static func live() -> AppEnvironment {
        let aiConversationService: AIConversationService = (try? APIClient())
            .map(AnthropicAIConversationService.init(client:))
            ?? UnconfiguredAIConversationService()

        return AppEnvironment(
            voiceEngine: DefaultVoiceEngine(),
            aiConversationService: aiConversationService,
            conversationStore: SwiftDataConversationStore()
        )
    }

    static func preview() -> AppEnvironment {
        AppEnvironment(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: MockAIConversationService(),
            conversationStore: InMemoryConversationStore()
        )
    }
}
