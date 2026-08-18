import Foundation
@testable import Ghost
import Testing

struct RoutingAIConversationServiceTests {
    @Test
    func fallsBackToUnconfiguredWhenNothingIsStored() async throws {
        let suiteName = "RoutingAIConversationServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let apiKeyStore = InMemoryAPIKeyStore()
        let service = RoutingAIConversationService(apiKeyStore: apiKeyStore, defaults: defaults)

        await #expect(throws: AIServiceError.self) {
            for try await _ in service.streamResponse(to: [], healthContext: nil) {}
        }
    }

    @Test
    func fallsBackToUnconfiguredForAnyStoredProviderWithoutAKey() async throws {
        let suiteName = "RoutingAIConversationServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(AIProvider.gemini.rawValue, forKey: AIProvider.preferencesKey)

        let apiKeyStore = InMemoryAPIKeyStore()
        let service = RoutingAIConversationService(apiKeyStore: apiKeyStore, defaults: defaults)

        await #expect(throws: AIServiceError.self) {
            for try await _ in service.streamResponse(to: [], healthContext: nil) {}
        }
    }
}
