import Foundation

/// Thin HTTP client. Provider-specific AI/voice adapters (added later)
/// build on top of this rather than each rolling their own URLSession
/// handling.
struct APIClient {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession

    /// Reads `GhostAPIBaseURL` / `GhostAIAPIKey` from Info.plist, which are
    /// substituted at build time from `Secrets.xcconfig`.
    init(session: URLSession = .shared) throws {
        guard
            let baseURLString = Bundle.main.object(forInfoDictionaryKey: "GhostAPIBaseURL") as? String,
            let baseURL = URL(string: baseURLString)
        else {
            throw NetworkError.missingConfiguration("GhostAPIBaseURL")
        }
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GhostAIAPIKey") as? String else {
            throw NetworkError.missingConfiguration("GhostAIAPIKey")
        }

        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    /// Exposes the configured API key for adapters whose provider expects a
    /// custom auth header (e.g. Anthropic's `x-api-key`) instead of this
    /// client's default `Authorization: Bearer` scheme.
    var authorizationKey: String { apiKey }

    func send(_ endpoint: Endpoint) async throws -> Data {
        var endpoint = endpoint
        endpoint.headers["Authorization"] = "Bearer \(apiKey)"

        let (data, response) = try await session.data(for: endpoint.urlRequest(baseURL: baseURL))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpStatus(httpResponse.statusCode)
        }
        return data
    }

    /// Streams raw bytes for endpoints that respond with server-sent
    /// events (used by streaming AI chat completions).
    func stream(_ endpoint: Endpoint) -> AsyncThrowingStream<Data, Error> {
        var mutableEndpoint = endpoint
        mutableEndpoint.headers["Authorization"] = "Bearer \(apiKey)"
        let endpoint = mutableEndpoint

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: endpoint.urlRequest(baseURL: baseURL))
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode) else {
                        throw NetworkError.invalidResponse
                    }
                    for try await line in bytes.lines {
                        continuation.yield(Data(line.utf8))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
