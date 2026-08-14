import AVFoundation

/// Converts raw audio buffers into normalized amplitude levels for the
/// waveform view. Not a "real" VAD (speech vs. silence classification) yet
/// — that's a natural place to plug in a provider-specific implementation
/// later without touching anything upstream.
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
}
