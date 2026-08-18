import AVFoundation

/// Converts raw audio buffers into normalized amplitude levels for the
/// waveform view, and a plain RMS amplitude usable for speech/silence
/// classification. Swap `rmsAmplitude`'s consumer for a provider-specific
/// VAD later without touching anything upstream.
enum VoiceActivityDetector {
    static func amplitudeLevels(from buffer: AVAudioPCMBuffer, bucketCount: Int = 24) -> [CGFloat] {
        guard let channelData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0, count: bucketCount)
        }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return Array(repeating: 0, count: bucketCount) }

        let samplesPerBucket = max(1, frameCount / bucketCount)

        return (0..<bucketCount).map { bucket in
            let start = bucket * samplesPerBucket
            let end = min(start + samplesPerBucket, frameCount)
            guard start < end else { return 0 }

            var sum: Float = 0
            for index in start..<end {
                sum += abs(channelData[index])
            }
            let average = sum / Float(end - start)
            return CGFloat(min(1, average * 8))
        }
    }

    /// Root-mean-square amplitude of the whole buffer — a simple loudness
    /// measure used to tell speech from silence.
    static func rmsAmplitude(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        var sumOfSquares: Float = 0
        for index in 0..<frameCount {
            let sample = channelData[index]
            sumOfSquares += sample * sample
        }
        return (sumOfSquares / Float(frameCount)).squareRoot()
    }
}
