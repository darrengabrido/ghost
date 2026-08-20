import Foundation
import SwiftData

/// Default `TimelineStore` backed by SwiftData. Owns its own
/// `ModelContainer`, same as `SwiftDataConversationStore` — only this file
/// would change if timeline persistence moved to something else.
@MainActor
final class SwiftDataTimelineStore: TimelineStore {
    private let container: ModelContainer

    init() {
        do {
            let configuration = ModelConfiguration(
                "Timeline",
                schema: Schema([TimelineEvent.self])
            )
            container = try ModelContainer(for: TimelineEvent.self, configurations: configuration)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    func save(_ events: [TimelineEvent]) async throws {
        for event in events {
            container.mainContext.insert(event)
        }
        try container.mainContext.save()
    }

    func recentEvents(since date: Date) async throws -> [TimelineEvent] {
        let descriptor = FetchDescriptor<TimelineEvent>(
            predicate: #Predicate { $0.timestamp >= date },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    func deleteAll() async throws {
        let events = try container.mainContext.fetch(FetchDescriptor<TimelineEvent>())
        for event in events {
            container.mainContext.delete(event)
        }
        try container.mainContext.save()
    }
}

/// In-memory `TimelineStore` for SwiftUI previews and tests — no disk
/// persistence.
@MainActor
final class InMemoryTimelineStore: TimelineStore {
    private var events: [TimelineEvent] = []

    func save(_ events: [TimelineEvent]) async throws {
        self.events.append(contentsOf: events)
    }

    func recentEvents(since date: Date) async throws -> [TimelineEvent] {
        events
            .filter { $0.timestamp >= date }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func deleteAll() async throws {
        events.removeAll()
    }
}
