import Foundation

/// Streams chat completions from xAI's Grok API
/// (`POST /v1/chat/completions`, server-sent events) using `APIClient` for
/// transport and `PromptBuilder` for turning `Message` history and Ghost's
/// persona into a request body. Grok's API is intentionally
/// OpenAI-compatible, but kept as its own adapter (rather than sharing
/// `OpenAIAIConversationService`) so either can diverge or be swapped
/// independently.
struct GrokAIConversationService: AIConversationService {
    // Swap this if xAI ships a newer flagship model by the time you're
    // reading this — there's no way to discover it at runtime.
    private static let model = "grok-4"

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
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
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        guard let payloadData = payload.data(using: .utf8) else { continue }

                        let chunk = try JSONDecoder().decode(StreamChunk.self, from: payloadData)
                        if let text = chunk.choices.first?.delta.content {
                            continuation.yield(text)
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
            .map { RequestBody.Turn(role: $0.role, content: $0.content) }

        let body = RequestBody(model: Self.model, stream: true, messages: turns)

        return Endpoint(
            path: "/v1/chat/completions",
            method: "POST",
            headers: [
                "content-type": "application/json",
                "Authorization": "Bearer \(try client.requireAPIKey())"
            ],
            body: try JSONEncoder().encode(body)
        )
    }
}

private struct RequestBody: Encodable {
    let model: String
    let stream: Bool
    let messages: [Turn]

    struct Turn: Encodable {
        let role: String
        let content: String
    }
}

/// A single Grok streaming chunk (OpenAI-compatible shape). Only the text
/// delta Ghost's minimal handling needs is decoded.
private struct StreamChunk: Decodable {
    let choices: [Choice]
}

private struct Choice: Decodable {
    let delta: Delta
}

private struct Delta: Decodable {
    let content: String?
}
