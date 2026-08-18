import Foundation

/// Streams chat completions from the Anthropic Claude API
/// (`POST /v1/messages`, server-sent events) using `APIClient` for
/// transport and `PromptBuilder` for turning `Message` history and Ghost's
/// persona into a request body.
struct AnthropicAIConversationService: AIConversationService {
    private static let anthropicVersion = "2023-06-01"
    private static let maxTokens = 1024

    private let client: APIClient
    private let model: String

    init(client: APIClient, model: String) {
        self.client = client
        self.model = model
    }

    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let endpoint = try makeEndpoint(for: messages, healthContext: healthContext)
                    for try await lineData in client.stream(endpoint) {
                        guard
                            let line = String(data: lineData, encoding: .utf8),
                            line.hasPrefix("data:")
                        else { continue }

                        let payload = line.dropFirst("data:".count)
                            .trimmingCharacters(in: .whitespaces)
                        guard let payloadData = payload.data(using: .utf8) else { continue }

                        let event = try JSONDecoder().decode(StreamEvent.self, from: payloadData)
                        switch event.type {
                        case "content_block_delta":
                            if let text = event.delta?.text {
                                continuation.yield(text)
                            }
                        case "error":
                            throw AnthropicServiceError.apiError(
                                event.error?.message ?? "Anthropic returned an unknown error."
                            )
                        case "message_stop":
                            continuation.finish()
                            return
                        default:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func makeEndpoint(for messages: [Message], healthContext: String?) throws -> Endpoint {
        let turns = PromptBuilder.chatTurns(from: messages, healthContext: healthContext)
            .filter { $0.role != "system" }
            .map { RequestBody.Turn(role: $0.role, content: $0.content) }

        let body = RequestBody(
            model: model,
            maxTokens: Self.maxTokens,
            system: PromptBuilder.systemPrompt(healthContext: healthContext),
            stream: true,
            messages: turns
        )

        return Endpoint(
            path: "/v1/messages",
            method: "POST",
            headers: [
                "content-type": "application/json",
                "anthropic-version": Self.anthropicVersion,
                "x-api-key": try client.requireAPIKey()
            ],
            body: try JSONEncoder().encode(body)
        )
    }
}

enum AnthropicServiceError: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            "Ghost's brain had trouble responding: \(message)"
        }
    }
}

private struct RequestBody: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let stream: Bool
    let messages: [Turn]

    struct Turn: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case stream
        case messages
    }
}

/// A single Anthropic streaming event. Only the fields Ghost's minimal
/// text-delta handling needs are decoded — thinking blocks, tool use, and
/// usage metadata are ignored.
private struct StreamEvent: Decodable {
    let type: String
    let delta: Delta?
    let error: ErrorPayload?

    struct Delta: Decodable {
        let type: String?
        let text: String?
    }

    struct ErrorPayload: Decodable {
        let message: String?
    }
}
