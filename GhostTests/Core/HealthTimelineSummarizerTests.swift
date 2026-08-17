import Foundation
@testable import Ghost
import Testing

struct HealthTimelineSummarizerTests {
    @Test
    func summarizeDescribesEachMetricNaturallyWithoutRawJSON() throws {
        let events = [
            TimelineEvent(
                timestamp: .now,
                type: HealthMetricType.steps.timelineEventType,
                payload: #"{"value":8200,"unit":"count"}"#
            ),
            TimelineEvent(
                timestamp: .now,
                type: HealthMetricType.heartRate.timelineEventType,
                payload: #"{"value":68,"unit":"bpm"}"#
            ),
            TimelineEvent(
                timestamp: .now,
                type: HealthMetricType.sleep.timelineEventType,
                payload: #"{"value":6.5,"unit":"hr"}"#
            )
        ]

        let summary = try #require(HealthTimelineSummarizer.summarize(events))

        #expect(summary.contains("8200 steps"))
        #expect(summary.contains("68 bpm"))
        #expect(summary.contains("6.5 hours of sleep"))
    }

    @Test
    func summarizeIgnoresUnrelatedOrMalformedEvents() {
        let events = [
            TimelineEvent(timestamp: .now, type: "calendar.event", payload: #"{"title":"Standup"}"#),
            TimelineEvent(timestamp: .now, type: HealthMetricType.steps.timelineEventType, payload: "not json")
        ]

        #expect(HealthTimelineSummarizer.summarize(events) == nil)
    }

    @Test
    func summarizeReturnsNilForEmptyTimeline() {
        #expect(HealthTimelineSummarizer.summarize([]) == nil)
    }
}
