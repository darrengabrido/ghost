@testable import Ghost
import Testing

@MainActor
struct AppEnvironmentAIProviderTests {
    @Test
    func fallsBackToUnconfiguredWhenNoKeyIsSaved() {
        let apiKeyStore = InMemoryAPIKeyStore()

        for provider in AIProvider.allCases {
            let service = AppEnvironment.makeAIConversationService(provider: provider, apiKeyStore: apiKeyStore)
            #expect(service is UnconfiguredAIConversationService)
        }
    }

    @Test
    func buildsTheMatchingAdapterOncePerProviderKeyIsSaved() throws {
        let apiKeyStore = InMemoryAPIKeyStore()
        try apiKeyStore.save("test-key", for: .anthropic)
        try apiKeyStore.save("test-key", for: .openAI)
        try apiKeyStore.save("test-key", for: .grok)
        try apiKeyStore.save("test-key", for: .gemini)

        #expect(
            AppEnvironment.makeAIConversationService(provider: .anthropic, apiKeyStore: apiKeyStore)
                is AnthropicAIConversationService
        )
        #expect(
            AppEnvironment.makeAIConversationService(provider: .openAI, apiKeyStore: apiKeyStore)
                is OpenAIAIConversationService
        )
        #expect(
            AppEnvironment.makeAIConversationService(provider: .grok, apiKeyStore: apiKeyStore)
                is GrokAIConversationService
        )
        #expect(
            AppEnvironment.makeAIConversationService(provider: .gemini, apiKeyStore: apiKeyStore)
                is GeminiAIConversationService
        )
    }
}
