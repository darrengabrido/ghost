import Foundation

/// The conversational brain behind Ghost. Implementations stream response
/// tokens as they arrive so the UI (and eventually speech synthesis) can
/// start reacting before the full reply is generated.
///
/// `AnthropicAIConversationService` is the live default, used by
/// `AppEnvironment.live()` whenever an API key is configured. Add another
/// adapter (OpenAI, a self-hosted model, ...) the same way to make the
/// provider swappable at runtime.
protocol AIConversationService {
    /// - Parameter healthContext: a short natural-language summary of the
    ///   user's recent health patterns (see `HealthTimelineSummarizer`), or
    ///   `nil` when none is available. Implementations should fold this
    ///   into the system prompt rather than the visible chat turns.
    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error>
}

extension AIConversationService {
    func streamResponse(to messages: [Message]) -> AsyncThrowingStream<String, Error> {
        streamResponse(to: messages, healthContext: nil)
    }
}

/// Fallback used when no API key is configured, so the app is runnable out
/// of the box instead of crashing. `AppEnvironment.live()` falls back to
/// this only when constructing `APIClient` fails (no key in
/// `Secrets.xcconfig` / Keychain); once a key is set, `AnthropicAIConversationService`
/// is used instead.
struct UnconfiguredAIConversationService: AIConversationService {
    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIServiceError.unconfigured)
        }
    }
}

enum AIServiceError: LocalizedError {
    case unconfigured

    var errorDescription: String? {
        switch self {
        case .unconfigured:
            "Ghost doesn't have an AI provider configured yet. See AIConversationService.swift."
        }
    }
}
