import Foundation

@MainActor
protocol TimelineStore {
    func save(_ events: [TimelineEvent]) async throws
    func recentEvents(since date: Date) async throws -> [TimelineEvent]
    func deleteAll() async throws
}
