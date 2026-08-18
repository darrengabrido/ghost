import Foundation

/// Streams generated content from the Google Gemini API
/// (`POST /v1beta/models/{model}:streamGenerateContent`, server-sent
/// events) using `APIClient` for transport and `PromptBuilder` for turning
/// `Message` history and Ghost's persona into a request body. Gemini's
/// request/response shape differs from the OpenAI-style providers (no
/// `[DONE]` sentinel, roles are "user"/"model", the system prompt is a
/// separate `systemInstruction` field), so it isn't shared with them.
struct GeminiAIConversationService: AIConversationService {
    // Swap this if Google ships a newer flagship model by the time you're
    // reading this — there's no way to discover it at runtime.
    private static let model = "gemini-2.5-pro"

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
                        guard let payloadData = payload.data(using: .utf8) else { continue }

                        let chunk = try JSONDecoder().decode(StreamChunk.self, from: payloadData)
                        if let text = chunk.candidates?.first?.content?.parts?.first?.text {
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
            .filter { $0.role != "system" }

        let contents: [RequestBody.Content] = turns.map { turn in
            let role = turn.role == "user" ? "user" : "model"
            let part = RequestBody.Part(text: turn.content)
            return RequestBody.Content(role: role, parts: [part])
        }

        let systemPart = RequestBody.Part(text: PromptBuilder.systemPrompt(healthContext: healthContext))
        let body = RequestBody(
            systemInstruction: RequestBody.SystemInstruction(parts: [systemPart]),
            contents: contents
        )

        return Endpoint(
            path: "/v1beta/models/\(Self.model):streamGenerateContent",
            method: "POST",
            headers: [
                "content-type": "application/json",
                "x-goog-api-key": try client.requireAPIKey()
            ],
            queryItems: [URLQueryItem(name: "alt", value: "sse")],
            body: try JSONEncoder().encode(body)
        )
    }
}

private struct RequestBody: Encodable {
    struct Part: Encodable {
        let text: String
    }
    struct Content: Encodable {
        let role: String
        let parts: [Part]
    }
    struct SystemInstruction: Encodable {
        let parts: [Part]
    }

    let systemInstruction: SystemInstruction
    let contents: [Content]
}

/// A single Gemini streaming chunk. Only the text part Ghost's minimal
/// handling needs is decoded — safety ratings and usage metadata are
/// ignored.
private struct StreamChunk: Decodable {
    let candidates: [Candidate]?
}

private struct Candidate: Decodable {
    let content: CandidateContent?
}

private struct CandidateContent: Decodable {
    let parts: [CandidatePart]?
}

private struct CandidatePart: Decodable {
    let text: String?
}
