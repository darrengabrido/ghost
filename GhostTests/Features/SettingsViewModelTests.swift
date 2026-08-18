@testable import Ghost
import Testing

@MainActor
struct SettingsViewModelTests {
    @Test
    func preferenceWritesFlowThroughToTheStore() {
        let preferences = InMemoryUserPreferencesStore()
        let viewModel = makeViewModel(preferences: preferences)

        viewModel.speechRate = 0.8
        viewModel.isVoiceInterruptionEnabled = false
        viewModel.voiceIdentifier = "com.apple.voice.test"

        #expect(preferences.speechRate == 0.8)
        #expect(preferences.isVoiceInterruptionEnabled == false)
        #expect(preferences.voiceIdentifier == "com.apple.voice.test")
    }

    @Test
    func saveAPIKeyStoresTrimmedValueAndClearsDraft() throws {
        let apiKeyStore = InMemoryAPIKeyStore()
        let viewModel = makeViewModel(apiKeyStore: apiKeyStore)

        viewModel.draftAPIKey = "  sk-test-key  "
        viewModel.saveAPIKey()

        #expect(try apiKeyStore.savedKey() == "sk-test-key")
        #expect(viewModel.draftAPIKey.isEmpty)
        #expect(viewModel.apiKeyStatus == .keychain)
        #expect(viewModel.keychainHasKey)
    }

    @Test
    func saveAPIKeyIgnoresPlaceholderValues() throws {
        let apiKeyStore = InMemoryAPIKeyStore()
        let viewModel = makeViewModel(apiKeyStore: apiKeyStore)

        viewModel.draftAPIKey = "replace-with-your-anthropic-api-key"
        viewModel.saveAPIKey()

        #expect(try apiKeyStore.savedKey() == nil)
        #expect(viewModel.apiKeyStatus == .missing)
    }

    @Test
    func removeAPIKeyClearsTheStore() throws {
        let apiKeyStore = InMemoryAPIKeyStore(key: "sk-existing")
        let viewModel = makeViewModel(apiKeyStore: apiKeyStore)

        #expect(viewModel.apiKeyStatus == .keychain)
        viewModel.removeAPIKey()

        #expect(try apiKeyStore.savedKey() == nil)
        #expect(viewModel.apiKeyStatus == .missing)
        #expect(!viewModel.keychainHasKey)
    }

    @Test
    func switchingProviderClearsDraftAndShowsThatProvidersKeyStatus() throws {
        let apiKeyStore = InMemoryAPIKeyStore()
        try apiKeyStore.save("sk-anthropic", for: .anthropic)
        let viewModel = makeViewModel(apiKeyStore: apiKeyStore)

        #expect(viewModel.selectedProvider == .anthropic)
        #expect(viewModel.apiKeyStatus == .keychain)

        viewModel.draftAPIKey = "unsaved draft"
        viewModel.selectedProvider = .openAI

        #expect(viewModel.draftAPIKey.isEmpty)
        #expect(viewModel.apiKeyStatus == .missing)
        #expect(!viewModel.keychainHasKey)
    }

    @Test
    func savingAKeyOnlyAffectsTheSelectedProvider() throws {
        let apiKeyStore = InMemoryAPIKeyStore()
        let viewModel = makeViewModel(apiKeyStore: apiKeyStore)

        viewModel.selectedProvider = .grok
        viewModel.draftAPIKey = "sk-grok"
        viewModel.saveAPIKey()

        #expect(try apiKeyStore.savedKey(for: .grok) == "sk-grok")
        #expect(try apiKeyStore.savedKey(for: .anthropic) == nil)

        viewModel.selectedProvider = .anthropic
        #expect(viewModel.apiKeyStatus == .missing)
    }

    @Test
    func clearHistoryDeletesAllSavedConversations() async throws {
        let store = InMemoryConversationStore()
        try await store.save([Message(speaker: .user, text: "hello")])
        try await store.save([Message(speaker: .user, text: "again")])
        #expect(try await store.fetchAll().count == 2)

        let viewModel = makeViewModel(conversationStore: store)
        await viewModel.clearHistory()

        #expect(try await store.fetchAll().isEmpty)
    }

    @Test
    func inMemoryConversationStoreDeleteAllIsIdempotent() async throws {
        let store = InMemoryConversationStore()
        try await store.deleteAll()
        #expect(try await store.fetchAll().isEmpty)
    }
}

@MainActor
private func makeViewModel(
    preferences: UserPreferencesStore = InMemoryUserPreferencesStore(),
    apiKeyStore: APIKeyStore = InMemoryAPIKeyStore(),
    conversationStore: ConversationStore = InMemoryConversationStore(),
    voiceEngine: VoiceEngine = MockVoiceEngine()
) -> SettingsViewModel {
    SettingsViewModel(
        preferences: preferences,
        apiKeyStore: apiKeyStore,
        conversationStore: conversationStore,
        voiceEngine: voiceEngine
    )
}
