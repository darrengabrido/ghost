import AVFoundation
@testable import Ghost

/// Scripted `AudioCapture` for exercising `TranscriptionService` without
/// touching `AVAudioEngine`. Never yields real buffers — provider mocks
/// don't need them — but reports whatever levels are scripted so tests can
/// verify amplitude forwarding.
final class MockAudioCapture: AudioCapture, @unchecked Sendable {
    var levelsToReport: [[CGFloat]] = []
    private(set) var stopCallCount = 0

    func startCapturing(
        onLevel: @escaping @Sendable ([CGFloat]) -> Void
    ) -> AsyncThrowingStream<CapturedAudioBuffer, Error> {
        AsyncThrowingStream { continuation in
            for levels in levelsToReport {
                onLevel(levels)
            }
            continuation.finish()
        }
    }

    func stop() {
        stopCallCount += 1
    }
}
