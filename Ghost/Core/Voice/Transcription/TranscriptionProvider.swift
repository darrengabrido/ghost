import AVFoundation

/// A single raw (uncleaned) result from a `TranscriptionProvider`. See
/// `TranscriptCleaner` for the normalization step that turns this into
/// text ready to hand to `AIConversationService`.
enum RawTranscriptEvent: Sendable {
    case partial(String)
    case final(String)
}

/// A speech-to-text engine: consumes captured audio buffers and produces
/// transcript text. This is the piece to swap when upgrading Ghost's STT —
/// from Apple's on-device `Speech` framework to a server-based provider
/// (Whisper, Deepgram, ElevenLabs, ...) — without touching audio capture
/// or anything downstream in the conversation pipeline.
///
/// Implementations choose their own streaming behavior: emit `.partial`
/// results as audio arrives for low-latency live transcription, or buffer
/// everything and emit a single `.final` result for batch/offline
/// transcription (e.g. transcribing a pre-recorded clip). Either way, the
/// returned stream finishes after a `.final` event, when `audio` finishes,
/// or when cancelled.
protocol TranscriptionProvider: Sendable {
    func transcribe(
        _ audio: AsyncThrowingStream<CapturedAudioBuffer, Error>
    ) -> AsyncThrowingStream<RawTranscriptEvent, Error>
}
