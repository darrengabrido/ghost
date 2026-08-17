import Foundation
@testable import Ghost
import Testing

@MainActor
struct HealthTimelineSyncServiceTests {
    @Test
    func syncNormalizesAndSavesSamplesWhenAuthorized() async throws {
        let provider = MockHealthDataProvider()
        let store = InMemoryTimelineStore()
        let service = HealthTimelineSyncService(provider: provider, timelineStore: store)
        let since = Date.now.addingTimeInterval(-86_400)

        let status = try await service.sync(since: since)

        #expect(status == .authorized)
        let events = try await store.recentEvents(since: since)
        #expect(events.count == provider.samplesToReturn.count)
        #expect(events.contains { $0.type == HealthMetricType.steps.timelineEventType })
        #expect(events.contains { $0.type == HealthMetricType.heartRate.timelineEventType })
        #expect(events.contains { $0.type == HealthMetricType.sleep.timelineEventType })
    }

    @Test
    func syncSavesNothingWhenPermissionIsDenied() async throws {
        let provider = MockHealthDataProvider()
        provider.authorizationStatusToReturn = .denied
        let store = InMemoryTimelineStore()
        let service = HealthTimelineSyncService(provider: provider, timelineStore: store)
        let since = Date.now.addingTimeInterval(-86_400)

        let status = try await service.sync(since: since)

        #expect(status == .denied)
        #expect(try await store.recentEvents(since: since).isEmpty)
    }

    @Test
    func syncReturnsUnavailableWhenHealthKitIsNotAvailable() async throws {
        let provider = MockHealthDataProvider()
        provider.isHealthDataAvailable = false
        let store = InMemoryTimelineStore()
        let service = HealthTimelineSyncService(provider: provider, timelineStore: store)
        let since = Date.now.addingTimeInterval(-86_400)

        let status = try await service.sync(since: since)

        #expect(status == .unavailable)
        #expect(try await store.recentEvents(since: .distantPast).isEmpty)
    }

    @Test
    func syncSavesNothingWhenNoSamplesAreAvailable() async throws {
        let provider = MockHealthDataProvider()
        provider.samplesToReturn = []
        let store = InMemoryTimelineStore()
        let service = HealthTimelineSyncService(provider: provider, timelineStore: store)
        let since = Date.now.addingTimeInterval(-86_400)

        let status = try await service.sync(since: since)

        #expect(status == .authorized)
        #expect(try await store.recentEvents(since: since).isEmpty)
    }
}
