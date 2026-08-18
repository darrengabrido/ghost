import Foundation
@testable import Ghost
import Testing

struct DefaultTranscriptionServiceTests {
    @Test
    func startTranscribingCleansAndForwardsProviderEvents() async throws {
        let audioCapture = MockAudioCapture()
        let provider = MockTranscriptionProvider()
        provider.eventsToEmit = [
            .partial("  hel  "),
            .partial("  hello  "),
            .final("  hello there   um  ")
        ]
        let service = DefaultTranscriptionService(audioCapture: audioCapture, provider: provider)

        var received: [TranscriptionEvent] = []
        for try await event in service.startTranscribing() {
            received.append(event)
        }

        #expect(received == [
            .partial("Hel"),
            .partial("Hello"),
            .final("Hello there")
        ])
    }

    @Test
    func startTranscribingForwardsAudioLevels() async throws {
        let audioCapture = MockAudioCapture()
        audioCapture.levelsToReport = [[0.5, 0.6]]
        let provider = MockTranscriptionProvider()
        provider.eventsToEmit = [.final("hi")]
        let service = DefaultTranscriptionService(audioCapture: audioCapture, provider: provider)

        nonisolated(unsafe) var reportedLevels: [[CGFloat]] = []
        for try await _ in service.startTranscribing(onLevel: { reportedLevels.append($0) }) {}

        #expect(reportedLevels == [[0.5, 0.6]])
    }

    @Test
    func stopStopsAudioCapture() {
        let audioCapture = MockAudioCapture()
        let provider = MockTranscriptionProvider()
        let service = DefaultTranscriptionService(audioCapture: audioCapture, provider: provider)

        service.stop()

        #expect(audioCapture.stopCallCount == 1)
    }
}
