import AVFoundation
@testable import Ghost
import Testing

struct VoiceActivityDetectorTests {
    @Test
    func rmsAmplitudeOfSilentBufferIsZero() throws {
        let buffer = try makeBuffer(samples: [0, 0, 0, 0])

        #expect(VoiceActivityDetector.rmsAmplitude(from: buffer) == 0)
    }

    @Test
    func rmsAmplitudeMatchesKnownMagnitude() throws {
        let buffer = try makeBuffer(samples: [0.5, -0.5, 0.5, -0.5])

        let rms = VoiceActivityDetector.rmsAmplitude(from: buffer)

        #expect(abs(rms - 0.5) < 0.0001)
    }

    @Test
    func rmsAmplitudeOfEmptyBufferIsZero() throws {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4))
        buffer.frameLength = 0

        #expect(VoiceActivityDetector.rmsAmplitude(from: buffer) == 0)
    }

    /// `#require` rather than `!`: a nil format or buffer here means the
    /// audio stack is unavailable, and a failed requirement says that in one
    /// line where a force unwrap would crash the whole test run.
    private func makeBuffer(samples: [Float]) throws -> AVAudioPCMBuffer {
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
        )
        buffer.frameLength = AVAudioFrameCount(samples.count)

        let channelData = try #require(buffer.floatChannelData)[0]
        for (index, sample) in samples.enumerated() {
            channelData[index] = sample
        }
        return buffer
    }
}
