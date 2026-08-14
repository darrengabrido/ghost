import Foundation

@MainActor
protocol ConversationStore {
    func save(_ messages: [Message]) async throws
    func fetchAll() async throws -> [ConversationRecord]
    func delete(_ record: ConversationRecord) async throws
}
