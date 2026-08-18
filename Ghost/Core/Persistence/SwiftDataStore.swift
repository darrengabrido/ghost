import Foundation
import SwiftData

/// Default `ConversationStore` backed by SwiftData. Owns its own
/// `ModelContainer` so the rest of the app doesn't need to know about
/// SwiftData at all — only this file would change if persistence moved
/// to something else.
@MainActor
final class SwiftDataConversationStore: ConversationStore {
    private let container: ModelContainer

    init() {
        do {
            let configuration = ModelConfiguration(
                "ConversationHistory",
                schema: Schema([ConversationRecord.self])
            )
            container = try ModelContainer(for: ConversationRecord.self, configurations: configuration)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    func save(_ messages: [Message]) async throws {
        guard let first = messages.first else { return }

        let transcript = messages
            .map { "\($0.speaker == .user ? "You" : "Ghost"): \($0.text)" }
            .joined(separator: "\n")

        let record = ConversationRecord(
            title: String(first.text.prefix(48)),
            transcript: transcript
        )
        container.mainContext.insert(record)
        try container.mainContext.save()
    }

    func fetchAll() async throws -> [ConversationRecord] {
        let descriptor = FetchDescriptor<ConversationRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    func delete(_ record: ConversationRecord) async throws {
        container.mainContext.delete(record)
        try container.mainContext.save()
    }

    func deleteAll() async throws {
        let records = try container.mainContext.fetch(FetchDescriptor<ConversationRecord>())
        for record in records {
            container.mainContext.delete(record)
        }
        try container.mainContext.save()
    }
}

/// In-memory `ConversationStore` for SwiftUI previews and unconfigured
/// early development — no disk persistence.
@MainActor
final class InMemoryConversationStore: ConversationStore {
    private var records: [ConversationRecord] = []

    func save(_ messages: [Message]) async throws {
        guard let first = messages.first else { return }
        records.append(ConversationRecord(title: String(first.text.prefix(48)), transcript: ""))
    }

    func fetchAll() async throws -> [ConversationRecord] {
        records
    }

    func delete(_ record: ConversationRecord) async throws {
        records.removeAll { $0.id == record.id }
    }

    func deleteAll() async throws {
        records.removeAll()
    }
}
