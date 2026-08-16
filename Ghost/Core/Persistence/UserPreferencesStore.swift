import Foundation

/// User-facing playback preferences. Class-bound so Settings and TTS share
/// one live instance — the next utterance always sees the latest values.
@MainActor
protocol UserPreferencesStore: AnyObject {
    var speechRate: Double { get set }
    var isVoiceInterruptionEnabled: Bool { get set }
    var voiceIdentifier: String { get set }
}

@Observable
@MainActor
final class UserDefaultsPreferencesStore: UserPreferencesStore {
    private enum Key {
        static let speechRate = "ghost.preferences.speechRate"
        static let interruption = "ghost.preferences.voiceInterruption"
        static let voiceIdentifier = "ghost.preferences.voiceIdentifier"
    }

    var speechRate: Double {
        didSet { defaults.set(speechRate, forKey: Key.speechRate) }
    }

    var isVoiceInterruptionEnabled: Bool {
        didSet { defaults.set(isVoiceInterruptionEnabled, forKey: Key.interruption) }
    }

    var voiceIdentifier: String {
        didSet { defaults.set(voiceIdentifier, forKey: Key.voiceIdentifier) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.speechRate) == nil {
            speechRate = 0.5
        } else {
            speechRate = defaults.double(forKey: Key.speechRate)
        }
        if defaults.object(forKey: Key.interruption) == nil {
            isVoiceInterruptionEnabled = true
        } else {
            isVoiceInterruptionEnabled = defaults.bool(forKey: Key.interruption)
        }
        voiceIdentifier = defaults.string(forKey: Key.voiceIdentifier) ?? ""
    }
}

@Observable
@MainActor
final class InMemoryUserPreferencesStore: UserPreferencesStore {
    var speechRate: Double
    var isVoiceInterruptionEnabled: Bool
    var voiceIdentifier: String

    init(
        speechRate: Double = 0.5,
        isVoiceInterruptionEnabled: Bool = true,
        voiceIdentifier: String = ""
    ) {
        self.speechRate = speechRate
        self.isVoiceInterruptionEnabled = isVoiceInterruptionEnabled
        self.voiceIdentifier = voiceIdentifier
    }
}
