import Foundation

/// Everything Ghost needs from HealthKit — permission and recent metrics —
/// behind one protocol so the rest of the app never imports HealthKit
/// directly. Mirrors `VoiceEngine`/`AIConversationService`: one protocol,
/// one production adapter, one mock.
@MainActor
protocol HealthDataProvider {
    /// `false` on devices/simulators where HealthKit itself is unavailable
    /// (distinct from the user denying permission).
    var isHealthDataAvailable: Bool { get }

    /// Requests read access to steps, heart rate, and sleep. HealthKit
    /// deliberately never reports back whether read access was actually
    /// granted for privacy reasons — a denied request surfaces later as
    /// empty results from `fetchRecentSamples`, not as `.denied` here.
    func requestAuthorization() async -> HealthAuthorizationStatus

    /// Recent core metrics since `date`, one sample per metric type that
    /// has data. Returns an empty array rather than throwing when a metric
    /// has no data in the window.
    func fetchRecentSamples(since date: Date) async throws -> [HealthSample]
}
