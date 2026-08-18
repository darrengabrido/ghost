import AVFoundation
@testable import Ghost
import Testing

struct VoiceActivityDetectorTests {
    @Test
    func rmsAmplitudeOfSilentBufferIsZero() {
        let buffer = makeBuffer(samples: [0, 0, 0, 0])

        #expect(VoiceActivityDetector.rmsAmplitude(from: buffer) == 0)
    }

    @Test
    func rmsAmplitudeMatchesKnownMagnitude() {
        let buffer = makeBuffer(samples: [0.5, -0.5, 0.5, -0.5])

        let rms = VoiceActivityDetector.rmsAmplitude(from: buffer)

        #expect(abs(rms - 0.5) < 0.0001)
    }

    @Test
    func rmsAmplitudeOfEmptyBufferIsZero() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4)!
        buffer.frameLength = 0

        #expect(VoiceActivityDetector.rmsAmplitude(from: buffer) == 0)
    }

    private func makeBuffer(samples: [Float]) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channelData = buffer.floatChannelData![0]
        for (index, sample) in samples.enumerated() {
            channelData[index] = sample
        }
        return buffer
    }
}
