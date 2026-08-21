import Foundation
import SwiftData

/// The title a saved conversation gets.
///
/// Ghost can now open a conversation itself (see `SpeakingDecision`), which
/// puts a Ghost message at index 0 — and titling a History row with a generic
/// proactive greeting would make every such row read the same. So the title
/// comes from what the *user* first said, falling back to the opening message
/// only when they never replied.
private func conversationTitle(for messages: [Message]) -> String? {
    guard let source = messages.first(where: { $0.speaker == .user }) ?? messages.first else { return nil }
    return String(source.text.prefix(48))
}

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
        guard let title = conversationTitle(for: messages) else { return }

        let transcript = messages
            .map { "\($0.speaker == .user ? "You" : "Ghost"): \($0.text)" }
            .joined(separator: "\n")

        let record = ConversationRecord(
            title: title,
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
    private var records: [ConversationRecord]

    init(seeded records: [ConversationRecord] = []) {
        self.records = records
    }

    func save(_ messages: [Message]) async throws {
        guard let title = conversationTitle(for: messages) else { return }
        records.append(ConversationRecord(title: title, transcript: ""))
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
