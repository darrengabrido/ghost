import Foundation
@testable import Ghost
import Testing

@MainActor
struct SpeakingDecisionTests {
    @Test
    func staleHealthDataSyncedBeforeTheLastInteractionStaysQuiet() async throws {
        // Scenario A: readings exist, but nothing has landed since the user
        // last interacted. v1 has no anomaly detection, so this stays quiet
        // because nothing is *new*, not because the content was mundane.
        let now = Date.now
        let lastInteractionAt = now.addingTimeInterval(-3 * 60 * 60)
        let events = try await makeEvents(sampleDate: lastInteractionAt.addingTimeInterval(-60 * 60))

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: lastInteractionAt,
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.noSignal))
    }

    @Test
    func rightAfterBeingTalkedToStaysQuiet() async throws {
        let now = Date.now
        let events = try await makeEvents(sampleDate: now)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now.addingTimeInterval(-90),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.tooSoonSinceLastInteraction))
    }

    @Test
    func recentlySpokeProactivelyStaysQuietEvenWithNewSignal() async throws {
        let now = Date.now
        let events = try await makeEvents(sampleDate: now)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now.addingTimeInterval(-60 * 60),
                lastProactiveSpeechAt: now.addingTimeInterval(-15 * 60),
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.tooSoonSinceLastProactiveSpeech))
    }

    @Test
    func quietHoursSuppressEvenAGenuineSignal() async throws {
        let now = try #require(Calendar.current.date(bySettingHour: 3, minute: 0, second: 0, of: .now))
        let events = try await makeEvents(sampleDate: now)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now.addingTimeInterval(-24 * 60 * 60),
                lastProactiveSpeechAt: nil,
                quietHours: QuietHours(startHour: 22, endHour: 7)   // wraps midnight
            )
        )

        #expect(outcome == .stayQuiet(.withinQuietHours))
    }

    @Test
    func userReturningAfterDaysAwayIsGreeted() async throws {
        let now = Date.now
        let events = try await makeEvents(sampleDate: now.addingTimeInterval(-2 * 24 * 60 * 60))

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now.addingTimeInterval(-3 * 24 * 60 * 60),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .speak(.userReturned))
    }

    @Test
    func shortSilenceWithNoNewSignalStaysQuiet() async throws {
        // Scenario G, revised from the scoping doc's original "2 days" gap:
        // a gap that long always clears the 6-hour return threshold and
        // produces `.userReturned` regardless of content — correctly, since
        // "welcome back" doesn't require anything to have happened. That
        // means a 2-day gap doesn't test what this scenario is meant to
        // test. A gap under the return threshold, with nothing new since,
        // is the actual test of "elapsed time alone isn't enough."
        let now = Date.now

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [],
                now: now,
                lastInteractionAt: now.addingTimeInterval(-2 * 60 * 60),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.noSignal))
    }

    /// Seeds `InMemoryTimelineStore` the way the app actually would: through
    /// `MockHealthDataProvider` → `HealthTimelineSyncService`, with the
    /// default samples' dates overridden to `sampleDate` so each scenario
    /// can control timing precisely.
    private func makeEvents(sampleDate: Date) async throws -> [TimelineEvent] {
        let provider = MockHealthDataProvider()
        provider.samplesToReturn = provider.samplesToReturn.map {
            HealthSample(type: $0.type, value: $0.value, unit: $0.unit, date: sampleDate)
        }
        let store = InMemoryTimelineStore()
        let service = HealthTimelineSyncService(provider: provider, timelineStore: store)
        _ = try await service.sync(since: .distantPast)
        return try await store.recentEvents(since: .distantPast)
    }
}
