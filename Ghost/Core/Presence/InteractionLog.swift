import Foundation

/// The two moments Ghost's speaking decision turns on: when the user last said
/// something to Ghost, and when Ghost last spoke without being asked to.
///
/// Deliberately its own small, explicitly-owned type rather than a field on an
/// existing store. The three tempting alternatives and why each was rejected:
///
/// - **Not `UserPreferencesStore`.** Its doc comment scopes it to user-facing
///   playback preferences; these are bookkeeping the user never sees or sets,
///   and putting them there would drag Settings and localization along with it.
/// - **Not derived from `ConversationStore.fetchAll().first?.createdAt`.**
///   `SwiftDataStore.save` inserts a *new* `ConversationRecord` on every turn,
///   so sorting by `createdAt` approximates "last turn" only by accident — an
///   implementation quirk, not a contract, and one that would go silently stale
///   if persistence ever upserts one record per session. The two `fetchAll()`
///   implementations don't even agree on order (SwiftData sorts newest-first,
///   `InMemoryConversationStore` returns insertion order), and none of it can
///   express `lastProactiveSpeechAt` at all.
/// - **Not a `TimelineEvent`.** `SpeakingDecision` reads the timeline as ambient
///   *signal*; logging Ghost's own speech there would make Ghost's last
///   utterance count as something new to react to, and let it re-trigger on
///   itself.
///
/// Class-bound so `AppEnvironment` hands one live instance to every
/// `ConversationViewModel`. A fresh view model is built on each navigation to
/// the conversation screen, so a cooldown held in the view model would reset
/// every time the user left the screen and came back.
@MainActor
protocol InteractionLog: AnyObject {
    var lastInteractionAt: Date? { get }
    var lastProactiveSpeechAt: Date? { get }

    func recordInteraction(at date: Date)
    func recordProactiveSpeech(at date: Date)
}

/// Production `InteractionLog`. Two `Date`s outlive a launch but carry no
/// structure worth a SwiftData model, so `UserDefaults` is the right size —
/// same idiom as `UserDefaultsPreferencesStore`.
@MainActor
final class UserDefaultsInteractionLog: InteractionLog {
    private enum Key {
        static let lastInteraction = "ghost.interaction.lastInteractionAt"
        static let lastProactiveSpeech = "ghost.interaction.lastProactiveSpeechAt"
    }

    private(set) var lastInteractionAt: Date?
    private(set) var lastProactiveSpeechAt: Date?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastInteractionAt = defaults.object(forKey: Key.lastInteraction) as? Date
        lastProactiveSpeechAt = defaults.object(forKey: Key.lastProactiveSpeech) as? Date
    }

    func recordInteraction(at date: Date) {
        lastInteractionAt = date
        defaults.set(date, forKey: Key.lastInteraction)
    }

    func recordProactiveSpeech(at date: Date) {
        lastProactiveSpeechAt = date
        defaults.set(date, forKey: Key.lastProactiveSpeech)
    }
}

/// In-memory `InteractionLog` for SwiftUI previews and tests — nothing survives
/// a relaunch. Both moments are init parameters so a test can start from any
/// point in a conversation's history.
@MainActor
final class InMemoryInteractionLog: InteractionLog {
    private(set) var lastInteractionAt: Date?
    private(set) var lastProactiveSpeechAt: Date?

    init(lastInteractionAt: Date? = nil, lastProactiveSpeechAt: Date? = nil) {
        self.lastInteractionAt = lastInteractionAt
        self.lastProactiveSpeechAt = lastProactiveSpeechAt
    }

    func recordInteraction(at date: Date) {
        lastInteractionAt = date
    }

    func recordProactiveSpeech(at date: Date) {
        lastProactiveSpeechAt = date
    }
}
