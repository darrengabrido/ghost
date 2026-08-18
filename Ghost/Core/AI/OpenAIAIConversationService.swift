import Foundation

/// Streams chat completions from the OpenAI API
/// (`POST /v1/chat/completions`, server-sent events) using `APIClient` for
/// transport and `PromptBuilder` for turning `Message` history and Ghost's
/// persona into a request body.
struct OpenAIAIConversationService: AIConversationService {
    // Swap this if OpenAI ships a newer flagship model by the time you're
    // reading this — there's no way to discover it at runtime.
    private static let model = "gpt-5"

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

/// A single OpenAI streaming chunk. Only the text delta Ghost's minimal
/// handling needs is decoded — usage metadata, tool calls, and logprobs
/// are ignored.
private struct StreamChunk: Decodable {
    let choices: [Choice]
}

private struct Choice: Decodable {
    let delta: Delta
}

private struct Delta: Decodable {
    let content: String?
}
