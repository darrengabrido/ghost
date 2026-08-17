import Foundation

/// Requests HealthKit permission, pulls recent core metrics, and normalizes
/// them onto the shared timeline. One obvious owner for that
/// permission → fetch → normalize → save sequence, instead of it being
/// duplicated at every call site.
@MainActor
struct HealthTimelineSyncService {
    let provider: HealthDataProvider
    let timelineStore: TimelineStore

    @discardableResult
    func sync(since date: Date) async throws -> HealthAuthorizationStatus {
        guard provider.isHealthDataAvailable else { return .unavailable }

        let status = await provider.requestAuthorization()
        guard status == .authorized else { return status }

        let samples = try await provider.fetchRecentSamples(since: date)
        guard !samples.isEmpty else { return status }

        try await timelineStore.save(samples.map { $0.makeTimelineEvent() })
        return status
    }
}
