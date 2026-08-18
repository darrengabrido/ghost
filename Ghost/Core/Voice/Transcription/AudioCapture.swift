import AVFoundation

/// Captures raw microphone audio as a stream of PCM buffers, decoupled
/// from whatever speech-to-text engine consumes them. This is the piece to
/// swap for a different audio source — e.g. reading a pre-recorded file
/// for batch/offline transcription, or a different live-capture pipeline —
/// without touching `TranscriptionProvider` implementations at all.
protocol AudioCapture: Sendable {
    /// Starts capturing. `onLevel` is invoked with normalized amplitude
    /// buckets for each buffer as it's captured — useful for waveform UI —
    /// kept separate from the buffer stream itself so `TranscriptionProvider`
    /// implementations never need to know it exists.
    func startCapturing(
        onLevel: @escaping @Sendable ([CGFloat]) -> Void
    ) -> AsyncThrowingStream<AVAudioPCMBuffer, Error>

    /// Stops capturing and tears down any underlying engine/tap.
    func stop()
}

/// Default `AudioCapture` using `AVAudioEngine` to tap the device
/// microphone. Requesting microphone/speech permissions is left to the
/// `TranscriptionProvider` (or whatever composes the pipeline) — this type
/// only starts the engine once asked and assumes authorization has already
/// been granted.
///
/// `@unchecked Sendable`: `AVAudioEngine` isn't `Sendable`, but the engine
/// is only ever touched from `startCapturing`/`stop`, and callers
/// (`DefaultTranscriptionService`) already serialize listen/stop cycles —
/// there's no concurrent access to guard against in practice.
final class MicrophoneAudioCapture: AudioCapture, @unchecked Sendable {
    private let audioEngine = AVAudioEngine()

    func startCapturing(
        onLevel: @escaping @Sendable ([CGFloat]) -> Void
    ) -> AsyncThrowingStream<AVAudioPCMBuffer, Error> {
        AsyncThrowingStream { continuation in
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            // Runs on CoreAudio's real-time render thread, not the main
            // queue — only touch thread-safe/local state in here.
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                onLevel(VoiceActivityDetector.amplitudeLevels(from: buffer))
                continuation.yield(buffer)
            }

            do {
                audioEngine.prepare()
                try audioEngine.start()
            } catch {
                continuation.finish(throwing: error)
                return
            }

            continuation.onTermination = { [weak self] _ in
                self?.stop()
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
