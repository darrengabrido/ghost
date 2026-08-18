import AVFoundation

/// A cleaned transcript event. Unlike `RawTranscriptEvent`, text here has
/// already been through `TranscriptCleaner` and is ready to display or
/// hand to `AIConversationService`.
enum TranscriptionEvent: Sendable, Equatable {
    case partial(String)
    case final(String)
}

/// Ghost's transcription pipeline: audio capture → speech-to-text →
/// cleanup, producing clean text ready for `AIConversationService`. This
/// is the entry point the rest of the app depends on — swap the
/// `AudioCapture` or `TranscriptionProvider` this is composed from (see
/// `DefaultTranscriptionService`) to change how Ghost listens or which STT
/// engine it uses without touching this protocol or its callers.
protocol TranscriptionService: Sendable {
    /// Starts a transcription session. The stream finishes after a
    /// `.final` event, when the underlying audio ends, or when cancelled.
    /// `onLevel` reports normalized amplitude for the waveform UI; pass a
    /// no-op closure (the default, via the `startTranscribing()` overload
    /// below) if the caller doesn't need it.
    func startTranscribing(
        onLevel: @escaping @Sendable ([CGFloat]) -> Void
    ) -> AsyncThrowingStream<TranscriptionEvent, Error>

    /// Stops capturing audio and ends the session immediately.
    func stop()
}

extension TranscriptionService {
    func startTranscribing() -> AsyncThrowingStream<TranscriptionEvent, Error> {
        startTranscribing(onLevel: { _ in })
    }
}

/// Default `TranscriptionService`, composed from an `AudioCapture` +
/// `TranscriptionProvider` pair plus `TranscriptCleaner`. Neither
/// dependency knows about the other — capture only knows about producing
/// audio buffers, the provider only knows about turning audio into text —
/// so either can be swapped independently (e.g. a file-based `AudioCapture`
/// for batch transcription, or a server-based `TranscriptionProvider` for
/// higher accuracy) without touching this type or anything downstream.
final class DefaultTranscriptionService: TranscriptionService, Sendable {
    private let audioCapture: any AudioCapture
    private let provider: any TranscriptionProvider

    init(audioCapture: any AudioCapture, provider: any TranscriptionProvider) {
        self.audioCapture = audioCapture
        self.provider = provider
    }

    func startTranscribing(
        onLevel: @escaping @Sendable ([CGFloat]) -> Void
    ) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { continuation in
            let audioStream = audioCapture.startCapturing(onLevel: onLevel)
            let task = Task {
                do {
                    for try await event in provider.transcribe(audioStream) {
                        switch event {
                        case .partial(let text):
                            continuation.yield(.partial(TranscriptCleaner.clean(text, isFinal: false)))
                        case .final(let text):
                            continuation.yield(.final(TranscriptCleaner.clean(text, isFinal: true)))
                            continuation.finish()
                            return
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.audioCapture.stop()
            }
        }
    }

    func stop() {
        audioCapture.stop()
    }
}
