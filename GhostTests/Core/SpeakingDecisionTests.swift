import Foundation
@testable import Ghost
import Testing

/// Scenarios A–E and G from the "should I speak right now" scoping doc.
/// Every case asserts on `SpeakingDecision.Outcome` — never on what Ghost would
/// have said. Signal is seeded through the same doubles the app uses
/// (`MockHealthDataProvider` → `HealthTimelineSyncService` → `InMemoryTimelineStore`)
/// where the scenario is about accumulated health data, and hand-constructed
/// `TimelineEvent`s where it's only about timing.
@MainActor
struct SpeakingDecisionTests {
    /// A — mundane pattern. The control case: a reading landing in the timeline
    /// is not itself a reason to interrupt.
    ///
    /// Note *why* this stays quiet in v1: three hours is short of
    /// `longSilenceThreshold`, not because Ghost judged the readings
    /// unremarkable. Ghost has no notion of "unusual" — that's the same missing
    /// baseline infrastructure that kept `.healthAnomaly` out of `SpeakReason`.
    @Test
    func mundaneHealthReadingsThreeHoursAfterTalkingStayQuiet() async throws {
        let now = try fixedDate(hour: 14)
        let events = try await syncedHealthEvents(
            samples: [
                HealthSample(type: .steps, value: 8_200, unit: "count", date: now - minutes(30)),
                HealthSample(type: .heartRate, value: 68, unit: "bpm", date: now - minutes(30)),
                HealthSample(type: .sleep, value: 6.5, unit: "hr", date: now - hours(7))
            ],
            now: now
        )

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now - hours(3),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.noSignal))
    }

    /// B — right after being talked to. A hard floor, ahead of any content
    /// evaluation: whatever else is true, don't interject on the heels of a
    /// conversation that just happened.
    @Test
    func ninetySecondsAfterTheUserSpokeStaysQuiet() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(1))],
                now: now,
                lastInteractionAt: now - 90,
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.tooSoonSinceLastInteraction))
    }

    /// C — Ghost already spoke recently. A cooldown separate from B: without
    /// it, Ghost could speak, re-trigger on the next checkpoint, and nag.
    /// The absence here is long enough that E's `.userReturned` would otherwise
    /// fire, so this proves the cooldown outranks it.
    @Test
    func fifteenMinutesAfterGhostSpokeStaysQuietEvenWithNewSignal() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(5))],
                now: now,
                lastInteractionAt: now - days(2),
                lastProactiveSpeechAt: now - minutes(15),
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.tooSoonSinceLastProactiveSpeech))
    }

    /// D — quiet hours. Respected unconditionally: there is no override tier in
    /// v1, so an otherwise-triggering signal at 3am still gets nothing.
    @Test
    func threeAmInsideQuietHoursStaysQuietDespiteATriggeringSignal() throws {
        let now = try fixedDate(hour: 3)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - hours(1))],
                now: now,
                lastInteractionAt: now - days(3),
                lastProactiveSpeechAt: nil,
                quietHours: QuietHours(startHour: 22, endHour: 7)
            )
        )

        #expect(outcome == .stayQuiet(.withinQuietHours))
    }

    /// E — the user returns after a long absence. The trigger is that they came
    /// back, not the accumulated data itself.
    @Test
    func returningAfterThreeDaysSpeaks() async throws {
        let now = try fixedDate(hour: 14)
        let events = try await syncedHealthEvents(
            samples: [
                HealthSample(type: .steps, value: 7_400, unit: "count", date: now - days(2.5)),
                HealthSample(type: .steps, value: 9_100, unit: "count", date: now - days(1.5)),
                HealthSample(type: .sleep, value: 6.8, unit: "hr", date: now - hours(9))
            ],
            now: now
        )

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now - days(3),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .speak(.userReturned))
    }

    /// G — long silence, genuinely nothing happened. The one that actually
    /// tests "silence is the default": elapsed time alone, with nothing new to
    /// report, is not sufficient justification to speak. Contrast with E, where
    /// the absence is comparable and the difference is unexamined signal.
    @Test
    func twoDaysOfSilenceWithAnEmptyTimelineStaysQuiet() async throws {
        let now = try fixedDate(hour: 14)
        let store = InMemoryTimelineStore()
        let events = try await store.recentEvents(since: now - days(7))

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: events,
                now: now,
                lastInteractionAt: now - days(2),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(events.isEmpty)
        #expect(outcome == .stayQuiet(.noSignal))
    }

    /// G, second half — "or unchanged since it was last surfaced". Events that
    /// predate the last interaction were already on the table when Ghost and
    /// the user last spoke, so they aren't new information now.
    @Test
    func twoDaysOfSilenceWithOnlyAlreadySurfacedEventsStaysQuiet() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - days(3)), event(at: now - days(2) - hours(1))],
                now: now,
                lastInteractionAt: now - days(2),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.noSignal))
    }

    /// Not one of the lettered scenarios, but the case that proves
    /// `.longSilenceCheckIn` is reachable at all — the same setup as A with the
    /// silence stretched past the threshold.
    @Test
    func newSignalAfterSixHoursOfSilenceSpeaks() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(20))],
                now: now,
                lastInteractionAt: now - hours(7),
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .speak(.longSilenceCheckIn))
    }

    /// Ghost reached out and the user never answered. Once the proactive
    /// cooldown lapses every other gate is satisfied again, so without this
    /// rule Ghost would re-open the same conversation hourly, forever — which
    /// is the exact "needy, checklist-y" failure the whole feature exists to
    /// avoid.
    @Test
    func afterAnUnansweredOpenerGhostStaysQuietEvenOnceTheCooldownLapses() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(1))],
                now: now,
                lastInteractionAt: now - days(3),
                lastProactiveSpeechAt: now - hours(2),
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.awaitingReply))
    }

    /// The other side of that rule: once the user actually says something,
    /// their reply becomes the newer moment and Ghost is free to open again on
    /// the next qualifying silence.
    @Test
    func onceTheUserRepliesGhostMayOpenAgainOnTheNextSilence() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(1))],
                now: now,
                lastInteractionAt: now - days(2),
                lastProactiveSpeechAt: now - days(3),
                quietHours: nil
            )
        )

        #expect(outcome == .speak(.userReturned))
    }

    /// A fresh install hasn't "returned" from anywhere — onboarding owns the
    /// first hello.
    @Test
    func noRecordedInteractionStaysQuiet() throws {
        let now = try fixedDate(hour: 14)

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: [event(at: now - minutes(5))],
                now: now,
                lastInteractionAt: nil,
                lastProactiveSpeechAt: nil,
                quietHours: nil
            )
        )

        #expect(outcome == .stayQuiet(.noSignal))
    }
}

@MainActor
struct QuietHoursTests {
    @Test
    func windowSpanningMidnightWrapsAround() {
        let quietHours = QuietHours(startHour: 22, endHour: 7)

        #expect(quietHours.contains(hour: 22))
        #expect(quietHours.contains(hour: 23))
        #expect(quietHours.contains(hour: 0))
        #expect(quietHours.contains(hour: 3))
        #expect(!quietHours.contains(hour: 7))
        #expect(!quietHours.contains(hour: 12))
        #expect(!quietHours.contains(hour: 21))
    }

    @Test
    func windowWithinOneDayDoesNotWrap() {
        let quietHours = QuietHours(startHour: 9, endHour: 17)

        #expect(quietHours.contains(hour: 9))
        #expect(quietHours.contains(hour: 16))
        #expect(!quietHours.contains(hour: 17))
        #expect(!quietHours.contains(hour: 3))
    }

    @Test
    func defaultWindowIsTenPmToSevenAm() throws {
        let earlyMorning = try fixedDate(hour: 3)
        let afternoon = try fixedDate(hour: 14)

        #expect(QuietHours.default == QuietHours(startHour: 22, endHour: 7))
        #expect(QuietHours.default.contains(earlyMorning))
        #expect(!QuietHours.default.contains(afternoon))
    }
}

// MARK: - Helpers

/// A fixed wall-clock moment, so nothing in this suite depends on when CI
/// happens to run it. Local-calendar based, matching how `QuietHours` reads the
/// hour in production.
private func fixedDate(hour: Int, calendar: Calendar = .current) throws -> Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 21
    components.hour = hour
    components.minute = 0
    components.second = 0
    return try #require(calendar.date(from: components))
}

/// A timeline event whose only interesting property is when it landed.
@MainActor
private func event(at timestamp: Date) -> TimelineEvent {
    TimelineEvent(timestamp: timestamp, type: HealthMetricType.steps.timelineEventType, payload: "{}")
}

/// Drives samples through the real normalize-and-save path rather than
/// hand-rolling `TimelineEvent`s, so these scenarios break if that path changes
/// shape.
@MainActor
private func syncedHealthEvents(samples: [HealthSample], now: Date) async throws -> [TimelineEvent] {
    let provider = MockHealthDataProvider()
    provider.samplesToReturn = samples
    let store = InMemoryTimelineStore()
    let syncService = HealthTimelineSyncService(provider: provider, timelineStore: store)

    let since = now - days(7)
    try await syncService.sync(since: since)
    return try await store.recentEvents(since: since)
}

private func minutes(_ count: Double) -> TimeInterval { count * 60 }
private func hours(_ count: Double) -> TimeInterval { count * 60 * 60 }
private func days(_ count: Double) -> TimeInterval { count * 24 * 60 * 60 }
