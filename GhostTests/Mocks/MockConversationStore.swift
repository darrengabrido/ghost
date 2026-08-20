@testable import Ghost

/// Scripted `ConversationStore` for exercising view models without SwiftData.
@MainActor
final class MockConversationStore: ConversationStore {
    var recordsToReturn: [ConversationRecord] = []
    private(set) var deletedRecords: [ConversationRecord] = []

    func save(_ messages: [Message]) async throws {}

    func fetchAll() async throws -> [ConversationRecord] {
        recordsToReturn
    }

    func delete(_ record: ConversationRecord) async throws {
        deletedRecords.append(record)
        recordsToReturn.removeAll { $0.id == record.id }
    }

    func deleteAll() async throws {
        recordsToReturn.removeAll()
    }
}
