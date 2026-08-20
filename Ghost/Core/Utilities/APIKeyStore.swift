import Foundation

/// Stores user-provided AI API keys, one per `AIProvider`. Production uses
/// the Keychain; tests and previews keep values in memory.
protocol APIKeyStore: AnyObject, Sendable {
    func savedKey(for provider: AIProvider) throws -> String?
    func save(_ key: String, for provider: AIProvider) throws
    func clear(for provider: AIProvider) throws
}

/// Convenience overloads defaulting to `.anthropic`, Ghost's original (and
/// still default) provider — keeps call sites that only ever dealt with
/// one provider unchanged.
extension APIKeyStore {
    func savedKey() throws -> String? { try savedKey(for: .anthropic) }
    func save(_ key: String) throws { try save(key, for: .anthropic) }
    func clear() throws { try clear(for: .anthropic) }
}

final class KeychainAPIKeyStore: APIKeyStore, Sendable {
    private func account(for provider: AIProvider) -> String {
        "ghost.\(provider.rawValue).apiKey"
    }

    func savedKey(for provider: AIProvider) throws -> String? {
        try KeychainStore.get(forKey: account(for: provider))
    }

    func save(_ key: String, for provider: AIProvider) throws {
        try KeychainStore.set(key, forKey: account(for: provider))
    }

    func clear(for provider: AIProvider) throws {
        try KeychainStore.delete(forKey: account(for: provider))
    }
}

/// In-memory `APIKeyStore` for tests and SwiftUI previews.
final class InMemoryAPIKeyStore: APIKeyStore, @unchecked Sendable {
    private let lock = NSLock()
    private var keys: [AIProvider: String]

    init(key: String? = nil, provider: AIProvider = .anthropic) {
        keys = key.map { [provider: $0] } ?? [:]
    }

    func savedKey(for provider: AIProvider) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return keys[provider]
    }

    func save(_ key: String, for provider: AIProvider) throws {
        lock.lock()
        defer { lock.unlock() }
        keys[provider] = key
    }

    func clear(for provider: AIProvider) throws {
        lock.lock()
        defer { lock.unlock() }
        keys[provider] = nil
    }
}
