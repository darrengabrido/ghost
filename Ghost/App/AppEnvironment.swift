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
    let userPreferences: UserPreferencesStore
    let apiKeyStore: APIKeyStore
    let healthDataProvider: HealthDataProvider
    let timelineStore: TimelineStore

    static func live() -> AppEnvironment {
        let userPreferences = UserDefaultsPreferencesStore()
        let apiKeyStore = KeychainAPIKeyStore()
        let synthesizer = AVSpeechSynthesizerAdapter(preferences: userPreferences)

        return AppEnvironment(
            voiceEngine: DefaultVoiceEngine(synthesizer: synthesizer),
            aiConversationService: RoutingAIConversationService(apiKeyStore: apiKeyStore),
            conversationStore: SwiftDataConversationStore(),
            userPreferences: userPreferences,
            apiKeyStore: apiKeyStore,
            healthDataProvider: HealthKitDataProvider(),
            timelineStore: SwiftDataTimelineStore()
        )
    }

    /// Builds the concrete adapter for `provider`, or
    /// `UnconfiguredAIConversationService` when it has no usable API key.
    /// `nonisolated` (despite `AppEnvironment` being `@MainActor`) so
    /// `RoutingAIConversationService.streamResponse`, which isn't
    /// main-actor-isolated, can call it fresh on every request.
    nonisolated static func makeAIConversationService(
        provider: AIProvider,
        apiKeyStore: APIKeyStore
    ) -> AIConversationService {
        guard let client = try? APIClient(provider: provider, apiKeyStore: apiKeyStore) else {
            return UnconfiguredAIConversationService()
        }
        switch provider {
        case .anthropic: return AnthropicAIConversationService(client: client)
        case .openAI: return OpenAIAIConversationService(client: client)
        case .grok: return GrokAIConversationService(client: client)
        case .gemini: return GeminiAIConversationService(client: client)
        }
    }

    static func preview() -> AppEnvironment {
        let userPreferences = InMemoryUserPreferencesStore()
        return AppEnvironment(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: MockAIConversationService(),
            conversationStore: InMemoryConversationStore(),
            userPreferences: userPreferences,
            apiKeyStore: InMemoryAPIKeyStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore()
        )
    }
}
