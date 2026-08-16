import AVFoundation

@MainActor
protocol SpeechSynthesizer {
    func speak(_ text: String) async throws
    func stopSpeaking()
}

/// Default text-to-speech using `AVSpeechSynthesizer`. Swap for a
/// higher-fidelity provider (e.g. ElevenLabs) by implementing
/// `SpeechSynthesizer` against that provider's audio API instead — the
/// rest of the app only depends on this protocol.
@MainActor
final class AVSpeechSynthesizerAdapter: NSObject, SpeechSynthesizer {
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Error>?
    private let preferences: UserPreferencesStore

    init(preferences: UserPreferencesStore) {
        self.preferences = preferences
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) async throws {
        let utterance = AVSpeechUtterance(string: text)
        if preferences.voiceIdentifier.isEmpty {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(identifier: preferences.voiceIdentifier)
                ?? AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = Float(preferences.speechRate)

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension AVSpeechSynthesizerAdapter: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            continuation?.resume()
            continuation = nil
        }
    }
}
