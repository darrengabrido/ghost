import Foundation
import HealthKit

/// Production `HealthDataProvider`, backed by `HKHealthStore`. Read-only —
/// Ghost never writes to HealthKit, so only `NSHealthShareUsageDescription`
/// and the `com.apple.developer.healthkit` entitlement are required.
@MainActor
final class HealthKitDataProvider: HealthDataProvider {
    private let store = HKHealthStore()

    private static let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount)
    private static let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
    private static let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)

    private static let readTypes = Set(
        ([stepsType, heartRateType, sleepType] as [HKObjectType?]).compactMap { $0 }
    )

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> HealthAuthorizationStatus {
        guard isHealthDataAvailable else { return .unavailable }

        do {
            try await store.requestAuthorization(toShare: [], read: Self.readTypes)
        } catch {
            Log.health.error("HealthKit authorization request failed: \(error.localizedDescription)")
            return .denied
        }

        // HealthKit doesn't expose read-authorization state (by design, so
        // apps can't infer what a user chose). A denied user still reaches
        // this point without an error — it just surfaces as empty results
        // from `fetchRecentSamples` below.
        return .authorized
    }

    func fetchRecentSamples(since date: Date) async throws -> [HealthSample] {
        guard isHealthDataAvailable else { return [] }

        async let steps = fetchStepCount(since: date)
        async let heartRate = fetchAverageHeartRate(since: date)
        async let sleep = fetchSleepHours(since: date)

        return await [steps, heartRate, sleep].compactMap { $0 }
    }

    private func fetchStepCount(since date: Date) async -> HealthSample? {
        guard let type = Self.stepsType else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: date, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = sum.doubleValue(for: .count())
                continuation.resume(returning: HealthSample(type: .steps, value: value, unit: "count", date: .now))
            }
            store.execute(query)
        }
    }

    private func fetchAverageHeartRate(since date: Date) async -> HealthSample? {
        guard let type = Self.heartRateType else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: date, end: .now)
        let bpm = HKUnit.count().unitDivided(by: .minute())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                guard let average = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let value = average.doubleValue(for: bpm)
                continuation.resume(returning: HealthSample(type: .heartRate, value: value, unit: "bpm", date: .now))
            }
            store.execute(query)
        }
    }

    private func fetchSleepHours(since date: Date) async -> HealthSample? {
        guard let type = Self.sleepType else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: date, end: .now)
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                guard totalSeconds > 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                let hours = totalSeconds / 3_600
                continuation.resume(returning: HealthSample(type: .sleep, value: hours, unit: "hr", date: .now))
            }
            store.execute(query)
        }
    }
}
