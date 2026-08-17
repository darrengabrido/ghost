import Foundation

/// The core HealthKit metrics Ghost pulls in. Each case maps to a
/// `TimelineEvent.type` string via `timelineEventType`, namespaced so the
/// timeline can hold other sources (calendar, etc.) without collisions.
enum HealthMetricType: String, CaseIterable, Sendable {
    case steps
    case heartRate
    case sleep

    var timelineEventType: String { "health.\(rawValue)" }
}
