import Foundation

/// A single HealthKit reading, already reduced to the one number Ghost
/// cares about (e.g. total steps, average heart rate) — HealthKit's own
/// sample/statistics types don't leave `Core/Health`.
struct HealthSample: Sendable, Equatable {
    let type: HealthMetricType
    let value: Double
    let unit: String
    let date: Date
}
