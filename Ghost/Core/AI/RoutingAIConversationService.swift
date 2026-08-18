import Foundation

/// Resolves the actual `AIConversationService` fresh on every call, based
/// on whatever provider and model are currently selected in Settings. This
/// is what `AppEnvironment.live()` hands out, so switching providers,
/// picking a different model, or saving a new key takes effect on the very
/// next message — no relaunch needed, the same way a Keychain key update
/// already applies immediately via `APIClient.requireAPIKey()`.
///
/// Reads the selection straight from `UserDefaults` rather than through
/// the `@MainActor`-isolated `UserPreferencesStore`, since
/// `AIConversationService` (and this call) isn't main-actor-isolated —
/// `UserDefaultsPreferencesStore` writes to the same keys.
struct RoutingAIConversationService: AIConversationService {
    private let apiKeyStore: APIKeyStore
    private let defaults: UserDefaults

    init(apiKeyStore: APIKeyStore, defaults: UserDefaults = .standard) {
        self.apiKeyStore = apiKeyStore
        self.defaults = defaults
    }

    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error> {
        let provider = defaults.string(forKey: AIProvider.preferencesKey)
            .flatMap(AIProvider.init(rawValue:)) ?? .anthropic
        let model = defaults.string(forKey: provider.modelPreferencesKey) ?? provider.defaultModel
        return AppEnvironment.makeAIConversationService(provider: provider, model: model, apiKeyStore: apiKeyStore)
            .streamResponse(to: messages, healthContext: healthContext)
    }
}
