@testable import Ghost
import Testing

struct APIKeyStoreTests {
    @Test
    func inMemoryStoreKeepsKeysSeparatePerProvider() throws {
        let store = InMemoryAPIKeyStore()

        try store.save("anthropic-key", for: .anthropic)
        try store.save("openai-key", for: .openAI)

        #expect(try store.savedKey(for: .anthropic) == "anthropic-key")
        #expect(try store.savedKey(for: .openAI) == "openai-key")
        #expect(try store.savedKey(for: .grok) == nil)
        #expect(try store.savedKey(for: .gemini) == nil)
    }

    @Test
    func clearingOneProviderLeavesOthersUntouched() throws {
        let store = InMemoryAPIKeyStore()
        try store.save("anthropic-key", for: .anthropic)
        try store.save("grok-key", for: .grok)

        try store.clear(for: .anthropic)

        #expect(try store.savedKey(for: .anthropic) == nil)
        #expect(try store.savedKey(for: .grok) == "grok-key")
    }

    @Test
    func zeroArgConvenienceMethodsDefaultToAnthropic() throws {
        let store = InMemoryAPIKeyStore()

        try store.save("legacy-key")

        #expect(try store.savedKey() == "legacy-key")
        #expect(try store.savedKey(for: .anthropic) == "legacy-key")

        try store.clear()
        #expect(try store.savedKey(for: .anthropic) == nil)
    }

    @Test
    func initWithKeyDefaultsToAnthropicProvider() throws {
        let store = InMemoryAPIKeyStore(key: "sk-existing")

        #expect(try store.savedKey(for: .anthropic) == "sk-existing")
        #expect(try store.savedKey(for: .openAI) == nil)
    }
}
