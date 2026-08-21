import Foundation

/// Decides whether Ghost should speak unprompted right now, given ambient
/// state, without deciding what it would actually say — that's still the
/// existing `PromptBuilder`/`AIConversationService` path. Kept a pure
/// function, like `TranscriptCleaner`/`HealthTimelineSummarizer`, so the
/// rules can be tested and evolved without touching where it's called from.
enum SpeakingDecision {
    struct Input {
        let recentTimelineEvents: [TimelineEvent]
        let now: Date
        let lastInteractionAt: Date?
        let lastProactiveSpeechAt: Date?
        let quietHours: QuietHours?
    }

    enum Outcome: Equatable {
        case stayQuiet(SuppressionReason)
        case speak(SpeakReason)
    }

    enum SuppressionReason: Equatable {
        case noSignal
        case tooSoonSinceLastInteraction
        case tooSoonSinceLastProactiveSpeech
        case withinQuietHours
    }

    /// `.healthAnomaly` is intentionally not a case here. It's blocked on a
    /// baseline/deviation-detection layer that doesn't exist yet —
    /// `HealthSample` is a flat point reading with no notion of "normal for
    /// this person," so there is currently no honest way to construct this
    /// case. Add it back once that classifier exists upstream, not before.
    enum SpeakReason: Equatable {
        case longSilenceCheckIn
        case userReturned
    }

    private static let interactionCooldown: TimeInterval = 5 * 60
    private static let proactiveSpeechCooldown: TimeInterval = 30 * 60
    private static let returnThreshold: TimeInterval = 6 * 60 * 60

    static func evaluate(_ input: Input) -> Outcome {
        if let last = input.lastInteractionAt, input.now.timeIntervalSince(last) < interactionCooldown {
            return .stayQuiet(.tooSoonSinceLastInteraction)
        }
        if let last = input.lastProactiveSpeechAt, input.now.timeIntervalSince(last) < proactiveSpeechCooldown {
            return .stayQuiet(.tooSoonSinceLastProactiveSpeech)
        }
        if let quietHours = input.quietHours,
           quietHours.contains(hour: Calendar.current.component(.hour, from: input.now)) {
            return .stayQuiet(.withinQuietHours)
        }
        if let last = input.lastInteractionAt, input.now.timeIntervalSince(last) >= returnThreshold {
            return .speak(.userReturned)
        }
        let referencePoint = max(input.lastInteractionAt ?? .distantPast, input.lastProactiveSpeechAt ?? .distantPast)
        if input.recentTimelineEvents.contains(where: { $0.timestamp > referencePoint }) {
            return .speak(.longSilenceCheckIn)
        }
        return .stayQuiet(.noSignal)
    }
}

/// An hour-of-day window during which Ghost never speaks unprompted, with
/// no override — `startHour`/`endHour` are in `0..<24` and may wrap
/// midnight (e.g. `22...7`), which a plain `ClosedRange<Int>` can't
/// represent without trapping at construction.
struct QuietHours: Equatable {
    let startHour: Int
    let endHour: Int

    func contains(hour: Int) -> Bool {
        startHour <= endHour
            ? (hour >= startHour && hour < endHour)
            : (hour >= startHour || hour < endHour)
    }
}
