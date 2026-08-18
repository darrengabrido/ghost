import Foundation

/// Scripted `HealthDataProvider` for SwiftUI previews and tests — no
/// HealthKit entitlement or device required.
@MainActor
final class MockHealthDataProvider: HealthDataProvider {
    var isHealthDataAvailable = true
    var authorizationStatusToReturn: HealthAuthorizationStatus = .authorized
    var samplesToReturn: [HealthSample] = [
        HealthSample(type: .steps, value: 8_200, unit: "count", date: .now),
        HealthSample(type: .heartRate, value: 68, unit: "bpm", date: .now),
        HealthSample(type: .sleep, value: 6.5, unit: "hr", date: .now)
    ]

    func requestAuthorization() async -> HealthAuthorizationStatus {
        authorizationStatusToReturn
    }

    func fetchRecentSamples(since date: Date) async throws -> [HealthSample] {
        samplesToReturn
    }
}
