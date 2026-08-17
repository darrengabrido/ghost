import Foundation

/// The conversational brain behind Ghost. Implementations stream response
/// tokens as they arrive so the UI (and eventually speech synthesis) can
/// start reacting before the full reply is generated.
///
/// No provider is wired in yet — implement this against whichever LLM API
/// you choose (OpenAI, Anthropic, a self-hosted model, ...) and construct
/// it in `AppEnvironment.live()`.
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

/// Placeholder used until a real provider is configured, so the app is
/// runnable out of the box instead of crashing. Replace `AppEnvironment
/// .live()`'s `aiConversationService` with a real adapter (built on
/// `APIClient` + `PromptBuilder`) when you pick a provider.
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
