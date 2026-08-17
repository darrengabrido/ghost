import Foundation

/// Outcome of requesting HealthKit permission — deliberately its own type
/// rather than `HKAuthorizationStatus` so `Core/Health` stays testable
/// without importing HealthKit outside `HealthKitDataProvider`.
enum HealthAuthorizationStatus: Sendable, Equatable {
    /// The device doesn't support HealthKit, or no health data is available.
    case unavailable
    case denied
    case authorized
}
