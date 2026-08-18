import AVFoundation
import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    enum APIKeyStatus {
        case keychain
        case buildTime
        case missing
    }

    var speechRate: Double {
        didSet { preferences.speechRate = speechRate }
    }

    var isVoiceInterruptionEnabled: Bool {
        didSet { preferences.isVoiceInterruptionEnabled = isVoiceInterruptionEnabled }
    }

    var voiceIdentifier: String {
        didSet { preferences.voiceIdentifier = voiceIdentifier }
    }

    var selectedProvider: AIProvider {
        didSet {
            guard oldValue != selectedProvider else { return }
            preferences.selectedAIProvider = selectedProvider
            draftAPIKey = ""
            refreshKeychainStatus()
        }
    }

    var draftAPIKey = ""
    var errorMessage: String?
    private(set) var keychainHasKey = false

    var englishVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
    }

    var selectedVoiceName: String {
        if voiceIdentifier.isEmpty {
            return String(localized: "settings.voice.default")
        }
        return englishVoices.first { $0.identifier == voiceIdentifier }?.name
            ?? String(localized: "settings.voice.default")
    }

    var apiKeyStatus: APIKeyStatus {
        if keychainHasKey { return .keychain }
        if selectedProvider == .anthropic,
           let key = bundle.object(forInfoDictionaryKey: "GhostAIAPIKey") as? String,
           !ConfigurationValue.isPlaceholder(key) {
            return .buildTime
        }
        return .missing
    }

    var version: String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var build: String {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private let preferences: UserPreferencesStore
    private let apiKeyStore: APIKeyStore
    private let conversationStore: ConversationStore
    private let voiceEngine: VoiceEngine
    private let bundle: Bundle

    init(
        preferences: UserPreferencesStore,
        apiKeyStore: APIKeyStore,
        conversationStore: ConversationStore,
        voiceEngine: VoiceEngine,
        bundle: Bundle = .main
    ) {
        self.preferences = preferences
        self.apiKeyStore = apiKeyStore
        self.conversationStore = conversationStore
        self.voiceEngine = voiceEngine
        self.bundle = bundle
        speechRate = preferences.speechRate
        isVoiceInterruptionEnabled = preferences.isVoiceInterruptionEnabled
        voiceIdentifier = preferences.voiceIdentifier
        selectedProvider = preferences.selectedAIProvider
        refreshKeychainStatus()
    }

    func saveAPIKey() {
        let trimmed = draftAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !ConfigurationValue.isPlaceholder(trimmed) else { return }
        do {
            try apiKeyStore.save(trimmed, for: selectedProvider)
            draftAPIKey = ""
            refreshKeychainStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAPIKey() {
        do {
            try apiKeyStore.clear(for: selectedProvider)
            refreshKeychainStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previewVoice() async {
        do {
            try await voiceEngine.speak(String(localized: "settings.voice.sample"))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearHistory() async {
        do {
            try await conversationStore.deleteAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshKeychainStatus() {
        let saved = try? apiKeyStore.savedKey(for: selectedProvider)
        keychainHasKey = saved.map { !ConfigurationValue.isPlaceholder($0) } ?? false
    }
}
