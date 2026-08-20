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

    /// UserDefaults key backing this provider's chosen model (see
    /// `UserPreferencesStore.selectedModel(for:)`), read the same
    /// direct-from-UserDefaults way `preferencesKey` is.
    var modelPreferencesKey: String {
        "ghost.preferences.selectedModel.\(rawValue)"
    }

    /// Used whenever the user hasn't picked a model for this provider yet.
    /// Swap these if a provider ships a newer flagship by the time you're
    /// reading this — there's no way to discover the current lineup at
    /// runtime, and Settings only offers `availableModels` plus a free-text
    /// override, not live discovery.
    var defaultModel: String {
        switch self {
        case .anthropic: "claude-sonnet-5"
        case .openAI: "gpt-5"
        case .grok: "grok-4"
        case .gemini: "gemini-2.5-pro"
        }
    }

    /// A short curated list for the Settings model picker — not
    /// exhaustive. `AIModelPickerView` also offers a free-text field for
    /// any other model ID the provider supports.
    var availableModels: [String] {
        switch self {
        case .anthropic: ["claude-opus-5", "claude-sonnet-5", "claude-haiku-4-5-20251001"]
        case .openAI: ["gpt-5", "gpt-5-mini"]
        case .grok: ["grok-4", "grok-4-fast"]
        case .gemini: ["gemini-2.5-pro", "gemini-2.5-flash"]
        }
    }
}
