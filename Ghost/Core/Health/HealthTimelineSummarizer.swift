import Foundation

/// Turns raw timeline events back into one short, natural-language phrase
/// for `PromptBuilder` — Ghost gets a feel for recent health patterns
/// without ever being handed raw numbers to recite verbatim.
enum HealthTimelineSummarizer {
    static func summarize(_ events: [TimelineEvent]) -> String? {
        let decoder = JSONDecoder()

        let phrases: [String] = HealthMetricType.allCases.compactMap { metric in
            guard
                let event = events.first(where: { $0.type == metric.timelineEventType }),
                let data = event.payload.data(using: .utf8),
                let payload = try? decoder.decode(HealthTimelinePayload.self, from: data)
            else { return nil }

            return phrase(for: metric, payload: payload)
        }

        guard !phrases.isEmpty else { return nil }
        return phrases.joined(separator: ", ") + "."
    }

    private static func phrase(for metric: HealthMetricType, payload: HealthTimelinePayload) -> String {
        switch metric {
        case .steps:
            "around \(Int(payload.value)) steps recently"
        case .heartRate:
            "an average heart rate around \(Int(payload.value)) bpm"
        case .sleep:
            "about \(String(format: "%.1f", payload.value)) hours of sleep last night"
        }
    }
}
