import Foundation

/// Every AI provider Ghost knows how to talk to. Each case pairs with
/// exactly one `AIConversationService` adapter (see
/// `AppEnvironment.makeAIConversationService`) — adding a provider means
/// adding a case here, one adapter file, and a switch arm, nothing else.
enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case anthropic
    case openAI
    case grok
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: "Anthropic Claude"
        case .openAI: "OpenAI"
        case .grok: "xAI Grok"
        case .gemini: "Google Gemini"
        }
    }

    /// Where requests go. Only Anthropic's can be overridden at build time
    /// (via `GHOST_API_BASE_URL` in `Secrets.xcconfig`, e.g. to point at a
    /// proxy) — the rest use their provider's well-known API host.
    var defaultBaseURL: URL {
        switch self {
        case .anthropic: URL(string: "https://api.anthropic.com")!
        case .openAI: URL(string: "https://api.openai.com")!
        case .grok: URL(string: "https://api.x.ai")!
        case .gemini: URL(string: "https://generativelanguage.googleapis.com")!
        }
    }

    /// UserDefaults key backing `UserPreferencesStore.selectedAIProvider`.
    /// Shared with `RoutingAIConversationService`, which reads it directly
    /// (rather than through the `@MainActor`-isolated preferences store)
    /// since `AIConversationService` isn't main-actor-isolated.
    static let preferencesKey = "ghost.preferences.selectedAIProvider"
}
