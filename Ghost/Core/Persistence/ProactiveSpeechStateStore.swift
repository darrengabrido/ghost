import Foundation

/// Bookkeeping for `SpeakingDecision` — when the user last interacted with
/// Ghost, and when Ghost last spoke unprompted. Deliberately separate from
/// `UserPreferencesStore`: that protocol is scoped to user-facing playback
/// preferences, and these two timestamps aren't something a user sets.
@MainActor
protocol ProactiveSpeechStateStore: AnyObject {
    var lastInteractionAt: Date? { get set }
    var lastProactiveSpeechAt: Date? { get set }
}

@Observable
@MainActor
final class UserDefaultsProactiveSpeechStateStore: ProactiveSpeechStateStore {
    private enum Key {
        static let lastInteractionAt = "ghost.ambient.lastInteractionAt"
        static let lastProactiveSpeechAt = "ghost.ambient.lastProactiveSpeechAt"
    }

    var lastInteractionAt: Date? {
        didSet { defaults.set(lastInteractionAt, forKey: Key.lastInteractionAt) }
    }

    var lastProactiveSpeechAt: Date? {
        didSet { defaults.set(lastProactiveSpeechAt, forKey: Key.lastProactiveSpeechAt) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastInteractionAt = defaults.object(forKey: Key.lastInteractionAt) as? Date
        lastProactiveSpeechAt = defaults.object(forKey: Key.lastProactiveSpeechAt) as? Date
    }
}

@Observable
@MainActor
final class InMemoryProactiveSpeechStateStore: ProactiveSpeechStateStore {
    var lastInteractionAt: Date?
    var lastProactiveSpeechAt: Date?

    init(lastInteractionAt: Date? = nil, lastProactiveSpeechAt: Date? = nil) {
        self.lastInteractionAt = lastInteractionAt
        self.lastProactiveSpeechAt = lastProactiveSpeechAt
    }
}
