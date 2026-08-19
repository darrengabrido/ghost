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

    /// The environment the app actually launches with.
    ///
    /// UI tests get the mock stack. The live one reaches HealthKit on the
    /// conversation screen, which puts a system permission sheet over the
    /// first frame — fatal for screenshots, and non-deterministic for any
    /// test that has to see what's behind it.
    static func resolved() -> AppEnvironment {
        ProcessInfo.processInfo.arguments.contains(Self.uiTestingArgument) ? .uiTesting() : .live()
    }

    /// Passed by `ScreenshotTests` via `XCUIApplication.launchArguments`.
    static let uiTestingArgument = "--ui-testing"

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
            timelineStore: InMemoryTimelineStore()
        )
    }

    private static var sampleConversations: [ConversationRecord] {
        let now = Date.now
        return [
            ConversationRecord(
                title: "What the wind sounded like from the ridge",
                createdAt: now.addingTimeInterval(-2 * 3_600),
                transcript: ""
            ),
            ConversationRecord(
                title: "Sleep, and why last night ran shorter",
                createdAt: now.addingTimeInterval(-26 * 3_600),
                transcript: ""
            ),
            ConversationRecord(
                title: "The long walk after the storm",
                createdAt: now.addingTimeInterval(-73 * 3_600),
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
            timelineStore: InMemoryTimelineStore()
        )
    }
}
