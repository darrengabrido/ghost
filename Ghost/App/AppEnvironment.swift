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
    let interactionLog: InteractionLog

    /// The environment the app actually launches with.
    ///
    /// UI tests get the mock stack. The live one reaches HealthKit on the
    /// conversation screen, which puts a system permission sheet over the
    /// first frame — fatal for screenshots, and non-deterministic for any
    /// test that has to see what's behind it.
    static func resolved() -> AppEnvironment {
        LaunchFlags.isUITesting ? .uiTesting() : .live()
    }

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
            timelineStore: SwiftDataTimelineStore(),
            interactionLog: UserDefaultsInteractionLog()
        )
    }

    /// Builds the concrete adapter for `provider`/`model`, or
    /// `UnconfiguredAIConversationService` when it has no usable API key.
    /// `nonisolated` (despite `AppEnvironment` being `@MainActor`) so
    /// `RoutingAIConversationService.streamResponse`, which isn't
    /// main-actor-isolated, can call it fresh on every request.
    nonisolated static func makeAIConversationService(
        provider: AIProvider,
        model: String,
        apiKeyStore: APIKeyStore
    ) -> AIConversationService {
        guard let client = try? APIClient(provider: provider, apiKeyStore: apiKeyStore) else {
            return UnconfiguredAIConversationService()
        }
        switch provider {
        case .anthropic: return AnthropicAIConversationService(client: client, model: model)
        case .openAI: return OpenAIAIConversationService(client: client, model: model)
        case .grok: return GrokAIConversationService(client: client, model: model)
        case .gemini: return GeminiAIConversationService(client: client, model: model)
        }
    }

    /// Mocks, plus seeded history — the History rows are a redesigned
    /// surface, and an empty state shows none of them.
    static func uiTesting() -> AppEnvironment {
        AppEnvironment(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: MockAIConversationService(),
            conversationStore: InMemoryConversationStore(seeded: sampleConversations),
            userPreferences: InMemoryUserPreferencesStore(),
            apiKeyStore: InMemoryAPIKeyStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )
    }

    /// Fixed timestamps, not offsets from `now`. These render as visible
    /// dates in the History rows, and a relative date would change the
    /// committed screenshot on every CI run.
    private static var sampleConversations: [ConversationRecord] {
        [
            ConversationRecord(
                title: "What the wind sounded like from the ridge",
                createdAt: Date(timeIntervalSince1970: 1_775_995_200),
                transcript: ""
            ),
            ConversationRecord(
                title: "Sleep, and why last night ran shorter",
                createdAt: Date(timeIntervalSince1970: 1_775_908_800),
                transcript: ""
            ),
            ConversationRecord(
                title: "The long walk after the storm",
                createdAt: Date(timeIntervalSince1970: 1_775_739_600),
                transcript: ""
            )
        ]
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
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )
    }
}
