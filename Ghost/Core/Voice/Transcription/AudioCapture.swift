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
    ) -> AsyncThrowingStream<CapturedAudioBuffer, Error>

    /// Stops capturing and tears down any underlying engine/tap.
    func stop()
}

/// A `Sendable` wrapper around a captured audio buffer. `AVAudioPCMBuffer`
/// itself isn't `Sendable` — it's a mutable class, and CoreAudio's own
/// buffers can be reused/rewritten across threads — so the Swift 6
/// concurrency checker won't let one cross into a `Task` or be consumed on
/// another task, even a freshly copied one it can't prove is unaliased.
/// `AudioCapture` implementations are expected to hand over only buffers
/// they've deep-copied and no longer touch themselves (see
/// `MicrophoneAudioCapture`), which makes wrapping them here safe by
/// construction rather than a blind suppression.
struct CapturedAudioBuffer: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
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
    ) -> AsyncThrowingStream<CapturedAudioBuffer, Error> {
        AsyncThrowingStream { continuation in
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            // Runs on CoreAudio's real-time render thread, not the main
            // queue — only touch thread-safe/local state in here.
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                onLevel(VoiceActivityDetector.amplitudeLevels(from: buffer))
                // CoreAudio owns `buffer` and may reuse/overwrite it the
                // instant this callback returns, so it isn't safe to hand
                // the original off to `continuation` for consumption on
                // another task — only a buffer nothing else can touch is.
                if let copy = buffer.copy() {
                    continuation.yield(CapturedAudioBuffer(buffer: copy))
                }
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

private extension AVAudioPCMBuffer {
    /// A deep copy of this buffer's audio data. `nil` only if allocation
    /// fails (e.g. out of memory).
    func copy() -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            return nil
        }
        copy.frameLength = frameLength

        let source = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)
        let destination = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for (sourceBuffer, destinationBuffer) in zip(source, destination) {
            guard let sourceData = sourceBuffer.mData, let destinationData = destinationBuffer.mData else { continue }
            let byteCount = Int(sourceBuffer.mDataByteSize)
            UnsafeMutableRawBufferPointer(start: destinationData, count: byteCount)
                .copyMemory(from: UnsafeRawBufferPointer(start: sourceData, count: byteCount))
        }
        return copy
    }
}
