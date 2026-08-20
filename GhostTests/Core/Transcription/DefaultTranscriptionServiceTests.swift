import Foundation
@testable import Ghost
import Synchronization
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

        // `onLevel` is `@escaping @Sendable`, so appending to a captured
        // local is a data race that Swift 6 rejects outright. A `Mutex` keeps
        // the collector safe without an `@unchecked Sendable` box.
        let reportedLevels = Mutex<[[CGFloat]]>([])
        for try await _ in service.startTranscribing(
            onLevel: { levels in reportedLevels.withLock { $0.append(levels) } }
        ) {}

        #expect(reportedLevels.withLock { $0 } == [[0.5, 0.6]])
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
