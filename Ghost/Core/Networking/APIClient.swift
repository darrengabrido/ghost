import Foundation

/// Thin HTTP client. Provider-specific AI/voice adapters build on top of
/// this rather than each rolling their own URLSession handling.
struct APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let apiKeyStore: APIKeyStore
    private let bundle: Bundle

    /// Reads `GhostAPIBaseURL` from Info.plist (substituted at build time
    /// from `Secrets.xcconfig`). The API key is resolved per request —
    /// Keychain first, then the build-time `GhostAIAPIKey` — so a key
    /// saved in Settings is picked up without restarting.
    init(
        session: URLSession = .shared,
        apiKeyStore: APIKeyStore,
        bundle: Bundle = .main
    ) throws {
        guard
            let baseURLString = bundle.object(forInfoDictionaryKey: "GhostAPIBaseURL") as? String,
            !ConfigurationValue.isPlaceholder(baseURLString),
            let baseURL = URL(string: baseURLString)
        else {
            throw NetworkError.missingConfiguration("GhostAPIBaseURL")
        }

        self.baseURL = baseURL
        self.session = session
        self.apiKeyStore = apiKeyStore
        self.bundle = bundle
    }

    /// The API key adapters should send. Prefers a Settings/Keychain value
    /// over the build-time plist key.
    func requireAPIKey() throws -> String {
        if let key = try apiKeyStore.savedKey(), !ConfigurationValue.isPlaceholder(key) {
            return key
        }
        if let key = bundle.object(forInfoDictionaryKey: "GhostAIAPIKey") as? String,
           !ConfigurationValue.isPlaceholder(key) {
            return key
        }
        throw NetworkError.missingConfiguration("GhostAIAPIKey")
    }

    func send(_ endpoint: Endpoint) async throws -> Data {
        var endpoint = endpoint
        endpoint.headers["Authorization"] = "Bearer \(try requireAPIKey())"

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
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var mutableEndpoint = endpoint
                    mutableEndpoint.headers["Authorization"] = "Bearer \(try requireAPIKey())"
                    let (bytes, response) = try await session.bytes(
                        for: mutableEndpoint.urlRequest(baseURL: baseURL)
                    )
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
