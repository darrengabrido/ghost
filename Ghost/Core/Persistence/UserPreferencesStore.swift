import Foundation

/// User-facing playback preferences. Class-bound so Settings and TTS share
/// one live instance — the next utterance always sees the latest values.
@MainActor
protocol UserPreferencesStore: AnyObject {
    var speechRate: Double { get set }
    var isVoiceInterruptionEnabled: Bool { get set }
    var voiceIdentifier: String { get set }
    var selectedAIProvider: AIProvider { get set }
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

    var selectedAIProvider: AIProvider {
        didSet { defaults.set(selectedAIProvider.rawValue, forKey: AIProvider.preferencesKey) }
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
        selectedAIProvider = defaults.string(forKey: AIProvider.preferencesKey)
            .flatMap(AIProvider.init(rawValue:)) ?? .anthropic
    }
}

@Observable
@MainActor
final class InMemoryUserPreferencesStore: UserPreferencesStore {
    var speechRate: Double
    var isVoiceInterruptionEnabled: Bool
    var voiceIdentifier: String
    var selectedAIProvider: AIProvider

    init(
        speechRate: Double = 0.5,
        isVoiceInterruptionEnabled: Bool = true,
        voiceIdentifier: String = "",
        selectedAIProvider: AIProvider = .anthropic
    ) {
        self.speechRate = speechRate
        self.isVoiceInterruptionEnabled = isVoiceInterruptionEnabled
        self.voiceIdentifier = voiceIdentifier
        self.selectedAIProvider = selectedAIProvider
    }
}
