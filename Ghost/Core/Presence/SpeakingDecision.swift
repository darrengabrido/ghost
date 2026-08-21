import Foundation

/// Whether Ghost should say something right now, and why.
///
/// A pure function over a fully-gathered snapshot — mirroring the
/// gather-then-transform split already in `ConversationViewModel.start()`
/// (impure sync, then pure `HealthTimelineSummarizer.summarize`) — so it stays
/// testable with plain equality and no mocks. A caseless `enum` namespace with
/// a `static func`, matching `TranscriptCleaner`, `HealthTimelineSummarizer`,
/// and `PromptBuilder`.
///
/// **Silence is the default, and that is a property of the logic rather than a
/// docstring.** Elapsed time alone never justifies speaking: there has to be
/// signal that landed *after* the last time Ghost or the user could have
/// surfaced it. Every threshold below is biased conservative on purpose — a
/// companion that is a little too chatty reads as needy fast, which cuts
/// against the "comfortable in silence, not performing insight" persona line in
/// `PromptBuilder`.
enum SpeakingDecision {
    /// A snapshot, not live protocol access, so `evaluate` can't reach for
    /// anything the caller didn't already decide to hand it.
    struct Input {
        let recentTimelineEvents: [TimelineEvent]
        let now: Date
        let lastInteractionAt: Date?
        let lastProactiveSpeechAt: Date?
        let quietHours: QuietHours?
    }

    /// Carries *why*, not *what to say* — the utterance itself still goes
    /// through the existing `PromptBuilder`/`AIConversationService` path.
    enum Outcome: Equatable {
        case stayQuiet(SuppressionReason)
        case speak(SpeakReason)
    }

    /// Split from `SpeakReason` rather than sharing one `Reason` enum so
    /// `.speak(.tooSoonSinceLastInteraction)` is unrepresentable — the type
    /// system should rule that out, not the tests.
    enum SuppressionReason: Equatable {
        case noSignal
        case tooSoonSinceLastInteraction
        case tooSoonSinceLastProactiveSpeech
        /// Ghost already reached out and the user hasn't answered yet.
        case awaitingReply
        case withinQuietHours
    }

    /// There is deliberately no `.healthAnomaly(HealthMetricType)` case here,
    /// and this is not a TODO someone forgot to do.
    ///
    /// It is **blocked on baseline/deviation detection existing at all**.
    /// `HealthSample` is a flat point reading, and nothing anywhere in the
    /// codebase can distinguish 145bpm-during-a-run from 145bpm-at-rest. Adding
    /// the case before that infrastructure lands would mean an enum case that
    /// nothing can honestly construct — its own kind of lie. Revisit it
    /// together with real anomaly classification, not on its own.
    ///
    /// There is likewise no `Urgency` dimension: nothing downstream can act on
    /// one today. `VoiceEngine.speak` has no priority concept and there is no
    /// notification system to route "high" differently from "low".
    enum SpeakReason: Equatable {
        /// Unexamined signal has accumulated across a long stretch of quiet.
        case longSilenceCheckIn
        /// The user came back after a long absence.
        case userReturned
    }

    /// A hard floor after the user speaks, checked before any content
    /// evaluation: whatever else is true, don't interject on the heels of a
    /// conversation that just happened.
    static let interactionFloor: TimeInterval = 5 * 60

    /// A *separate* floor after **Ghost** speaks. Without it Ghost could speak,
    /// re-trigger on the next checkpoint, and nag.
    static let proactiveSpeechCooldown: TimeInterval = 60 * 60

    /// The earliest a check-in is allowed, and only ever with unexamined signal
    /// behind it.
    static let longSilenceThreshold: TimeInterval = 6 * 60 * 60

    /// The absence that counts as the user having gone away and come back.
    static let userReturnThreshold: TimeInterval = 24 * 60 * 60

    static func evaluate(_ input: Input) -> Outcome {
        // Absolute, and first, so it beats every speak path unconditionally.
        // There is no override tier in v1: Ghost has no anomaly detection, so
        // there is nothing it could honestly judge worth waking someone for.
        if let quietHours = input.quietHours, quietHours.contains(input.now) {
            return .stayQuiet(.withinQuietHours)
        }

        // A fresh install has not "returned" from anywhere, and onboarding owns
        // the first hello.
        guard let lastInteractionAt = input.lastInteractionAt else {
            return .stayQuiet(.noSignal)
        }

        let silence = input.now.timeIntervalSince(lastInteractionAt)
        guard silence >= interactionFloor else {
            return .stayQuiet(.tooSoonSinceLastInteraction)
        }

        if let lastProactiveSpeechAt = input.lastProactiveSpeechAt,
           input.now.timeIntervalSince(lastProactiveSpeechAt) < proactiveSpeechCooldown {
            return .stayQuiet(.tooSoonSinceLastProactiveSpeech)
        }

        // One opener per silence. Ghost has already reached out and the user
        // hasn't said anything since, so reaching out again is nagging however
        // much time has passed.
        //
        // This is load-bearing rather than belt-and-braces: `HealthKitDataProvider`
        // stamps every aggregate `date: .now`, and nothing dedupes them, so a
        // sync always writes events newer than the watermark below. Without
        // this rule the "unexamined signal" test is satisfied on every screen
        // open, and a user who never replies gets a fresh opener each time the
        // cooldown lapses — indefinitely. It also settles the scoping doc's
        // open question about a daily cap, in the conservative direction.
        if let lastProactiveSpeechAt = input.lastProactiveSpeechAt, lastProactiveSpeechAt > lastInteractionAt {
            return .stayQuiet(.awaitingReply)
        }

        // "Unexamined" means it landed after the last moment Ghost or the user
        // could have surfaced it. This is what separates a long absence worth
        // opening on from a long absence where genuinely nothing happened.
        let watermark = max(lastInteractionAt, input.lastProactiveSpeechAt ?? lastInteractionAt)
        guard input.recentTimelineEvents.contains(where: { $0.timestamp > watermark }) else {
            return .stayQuiet(.noSignal)
        }

        if silence >= userReturnThreshold {
            return .speak(.userReturned)
        }
        if silence >= longSilenceThreshold {
            return .speak(.longSilenceCheckIn)
        }
        return .stayQuiet(.noSignal)
    }
}
