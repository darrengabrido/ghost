import Foundation

/// Stores a user-provided AI API key. Production uses the Keychain;
/// tests and previews keep the value in memory.
protocol APIKeyStore: AnyObject, Sendable {
    func savedKey() throws -> String?
    func save(_ key: String) throws
    func clear() throws
}

final class KeychainAPIKeyStore: APIKeyStore, Sendable {
    static let account = "ghost.anthropic.apiKey"

    func savedKey() throws -> String? {
        try KeychainStore.get(forKey: Self.account)
    }

    func save(_ key: String) throws {
        try KeychainStore.set(key, forKey: Self.account)
    }

    func clear() throws {
        try KeychainStore.delete(forKey: Self.account)
    }
}

/// In-memory `APIKeyStore` for tests and SwiftUI previews.
final class InMemoryAPIKeyStore: APIKeyStore, @unchecked Sendable {
    private let lock = NSLock()
    private var key: String?

    init(key: String? = nil) {
        self.key = key
    }

    func savedKey() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return key
    }

    func save(_ key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        self.key = key
    }

    func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        key = nil
    }
}
