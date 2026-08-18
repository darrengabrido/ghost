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

        let aiConversationService: AIConversationService
        if let client = try? APIClient(apiKeyStore: apiKeyStore) {
            aiConversationService = AnthropicAIConversationService(client: client)
        } else {
            aiConversationService = UnconfiguredAIConversationService()
        }

        return AppEnvironment(
            voiceEngine: DefaultVoiceEngine(synthesizer: synthesizer),
            aiConversationService: aiConversationService,
            conversationStore: SwiftDataConversationStore(),
            userPreferences: userPreferences,
            apiKeyStore: apiKeyStore,
            healthDataProvider: HealthKitDataProvider(),
            timelineStore: SwiftDataTimelineStore()
        )
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
