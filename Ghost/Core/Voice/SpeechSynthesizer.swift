import AVFoundation

@MainActor
protocol SpeechSynthesizer {
    func speak(_ text: String) async throws
}

/// Default text-to-speech using `AVSpeechSynthesizer`. Swap for a
/// higher-fidelity provider (e.g. ElevenLabs) by implementing
/// `SpeechSynthesizer` against that provider's audio API instead — the
/// rest of the app only depends on this protocol.
@MainActor
final class AVSpeechSynthesizerAdapter: NSObject, SpeechSynthesizer {
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) async throws {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            synthesizer.speak(utterance)
        }
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
