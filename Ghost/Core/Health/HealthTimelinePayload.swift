import Foundation

/// The JSON shape a `HealthSample` normalizes into for
/// `TimelineEvent.payload`.
struct HealthTimelinePayload: Codable, Equatable {
    let value: Double
    let unit: String
}

extension HealthSample {
    /// Normalizes this sample into the shared timeline event shape:
    /// timestamp, a namespaced type, and a JSON payload.
    func makeTimelineEvent() -> TimelineEvent {
        let payload = HealthTimelinePayload(value: value, unit: unit)
        let encoded = (try? JSONEncoder().encode(payload))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return TimelineEvent(timestamp: date, type: type.timelineEventType, payload: encoded)
    }
}
