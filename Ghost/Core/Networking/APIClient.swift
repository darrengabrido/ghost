import Foundation

/// Thin HTTP client, scoped to one `AIProvider`. Provider-specific AI
/// adapters build on top of this rather than each rolling their own
/// URLSession handling; each adapter is responsible for setting whatever
/// auth header its provider expects (see `requireAPIKey()`), since that
/// varies by provider (`x-api-key`, `Authorization: Bearer`, ...).
struct APIClient {
    let provider: AIProvider
    private let baseURL: URL
    private let session: URLSession
    private let apiKeyStore: APIKeyStore
    private let bundle: Bundle

    /// Fails to construct when no usable API key exists for `provider` —
    /// that's the signal `AppEnvironment` uses to fall back to
    /// `UnconfiguredAIConversationService`. The base URL always resolves
    /// (falling back to `provider.defaultBaseURL`), so it's the key, not
    /// the URL, that determines whether this provider is configured.
    init(
        provider: AIProvider,
        session: URLSession = .shared,
        apiKeyStore: APIKeyStore,
        bundle: Bundle = .main
    ) throws {
        self.provider = provider
        self.baseURL = Self.resolveBaseURL(for: provider, bundle: bundle)
        self.session = session
        self.apiKeyStore = apiKeyStore
        self.bundle = bundle
        _ = try requireAPIKey()
    }

    private static func resolveBaseURL(for provider: AIProvider, bundle: Bundle) -> URL {
        guard
            provider == .anthropic,
            let baseURLString = bundle.object(forInfoDictionaryKey: "GhostAPIBaseURL") as? String,
            !ConfigurationValue.isPlaceholder(baseURLString),
            let baseURL = URL(string: baseURLString)
        else {
            return provider.defaultBaseURL
        }
        return baseURL
    }

    /// The API key adapters should send, for `provider`. Prefers a
    /// Settings/Keychain value over the build-time plist key — Anthropic
    /// only, since the other providers have no `Secrets.xcconfig` entry.
    func requireAPIKey() throws -> String {
        if let key = try apiKeyStore.savedKey(for: provider), !ConfigurationValue.isPlaceholder(key) {
            return key
        }
        if provider == .anthropic,
           let key = bundle.object(forInfoDictionaryKey: "GhostAIAPIKey") as? String,
           !ConfigurationValue.isPlaceholder(key) {
            return key
        }
        throw NetworkError.missingConfiguration("\(provider.displayName) API key")
    }

    func send(_ endpoint: Endpoint) async throws -> Data {
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
                    let (bytes, response) = try await session.bytes(
                        for: endpoint.urlRequest(baseURL: baseURL)
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
