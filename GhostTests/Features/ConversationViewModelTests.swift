import Foundation
@testable import Ghost
import Testing

@MainActor
struct ConversationViewModelTests {
    @Test
    func micTappedTranscribesRespondsAndSpeaksAndPersists() async throws {
        let voiceEngine = MockVoiceEngine()
        let aiService = MockAIConversationService(reply: "hi there")
        let store = InMemoryConversationStore()

        let viewModel = ConversationViewModel(
            voiceEngine: voiceEngine,
            aiConversationService: aiService,
            conversationStore: store,
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )

        viewModel.micTapped()

        try await waitUntil { viewModel.orbState == .idle }

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages.first?.speaker == .user)
        #expect(viewModel.messages.last?.speaker == .ghost)
        #expect(try await store.fetchAll().count == 1)
    }

    @Test
    func startSyncsHealthDataAndMicTappedPassesItToTheAIService() async throws {
        var requestWasMade = false
        var capturedHealthContext: String?
        let aiService = MockAIConversationService(reply: "noted") { context in
            requestWasMade = true
            capturedHealthContext = context
        }
        let viewModel = ConversationViewModel(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: aiService,
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )

        await viewModel.start()
        viewModel.micTapped()

        try await waitUntil { viewModel.orbState == .idle }

        #expect(requestWasMade)
        #expect(capturedHealthContext?.contains("steps") == true)
    }

    @Test
    func startLeavesHealthContextNilWhenPermissionIsDenied() async throws {
        let healthProvider = MockHealthDataProvider()
        healthProvider.authorizationStatusToReturn = .denied
        var requestWasMade = false
        var capturedHealthContext: String?
        let aiService = MockAIConversationService(reply: "noted") { context in
            requestWasMade = true
            capturedHealthContext = context
        }
        let viewModel = ConversationViewModel(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: aiService,
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: healthProvider,
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )

        await viewModel.start()
        viewModel.micTapped()

        try await waitUntil { viewModel.orbState == .idle }

        #expect(requestWasMade)
        #expect(capturedHealthContext == nil)
    }

    @Test
    func micTappedWhileSpeakingInterruptsWhenEnabled() async throws {
        let voiceEngine = MockVoiceEngine()
        voiceEngine.holdSpeakUntilStopped = true
        let viewModel = ConversationViewModel(
            voiceEngine: voiceEngine,
            aiConversationService: MockAIConversationService(reply: "hi there"),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(isVoiceInterruptionEnabled: true),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )

        viewModel.micTapped()
        try await waitUntil { viewModel.orbState == .speaking }

        viewModel.micTapped()

        #expect(voiceEngine.stopSpeakingCallCount == 1)
        #expect(viewModel.orbState != .speaking)
    }

    @Test
    func micTappedWhileSpeakingIsIgnoredWhenInterruptionDisabled() async throws {
        let voiceEngine = MockVoiceEngine()
        voiceEngine.holdSpeakUntilStopped = true
        let viewModel = ConversationViewModel(
            voiceEngine: voiceEngine,
            aiConversationService: MockAIConversationService(reply: "hi there"),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(isVoiceInterruptionEnabled: false),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: InMemoryInteractionLog()
        )

        viewModel.micTapped()
        try await waitUntil { viewModel.orbState == .speaking }

        viewModel.micTapped()

        #expect(voiceEngine.stopSpeakingCallCount == 0)
        #expect(viewModel.orbState == .speaking)
        voiceEngine.stopSpeaking()
    }

    /// The screen-appear checkpoint, end to end: nobody tapped the mic, and
    /// Ghost still ends up with something to say. `quietHours: nil` because the
    /// production default (10pm–7am) would otherwise make this pass or fail
    /// depending on what time CI ran.
    @Test
    func startSpeaksProactivelyWhenTheUserHasBeenAwayForDays() async {
        let interactionLog = InMemoryInteractionLog(lastInteractionAt: Date.now.addingTimeInterval(-3 * 86_400))
        let viewModel = ConversationViewModel(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: MockAIConversationService(reply: "there you are"),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: interactionLog,
            quietHours: nil
        )

        await viewModel.start()

        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.speaker == .ghost)
        #expect(viewModel.orbState == .idle)
        #expect(interactionLog.lastProactiveSpeechAt != nil)
    }

    /// The same checkpoint, with the decision going the other way — proof that
    /// `start()` actually consults `SpeakingDecision` rather than speaking
    /// whenever it finds signal.
    @Test
    func startStaysQuietWhenTheUserJustSpoke() async {
        let interactionLog = InMemoryInteractionLog(lastInteractionAt: Date.now.addingTimeInterval(-90))
        let viewModel = ConversationViewModel(
            voiceEngine: MockVoiceEngine(),
            aiConversationService: MockAIConversationService(reply: "there you are"),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: interactionLog,
            quietHours: nil
        )

        await viewModel.start()

        #expect(viewModel.messages.isEmpty)
        #expect(interactionLog.lastProactiveSpeechAt == nil)
    }

    /// Tapping the mic while an unrequested opener is still generating has to
    /// interrupt it. Before this was cancellable the mic was simply dead until
    /// a network call the user never asked for finished.
    @Test
    func micTappedDuringAProactiveOpenerInterruptsIt() async throws {
        let voiceEngine = SilentVoiceEngine()
        let interactionLog = InMemoryInteractionLog(lastInteractionAt: Date.now.addingTimeInterval(-3 * 86_400))
        let viewModel = ConversationViewModel(
            voiceEngine: voiceEngine,
            aiConversationService: HangingAIConversationService(),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(),
            healthDataProvider: MockHealthDataProvider(),
            timelineStore: InMemoryTimelineStore(),
            interactionLog: interactionLog,
            quietHours: nil
        )

        let startTask = Task { await viewModel.start() }
        try await waitUntil { viewModel.orbState == .thinking }

        viewModel.micTapped()
        await startTask.value

        #expect(viewModel.orbState == .listening)
        #expect(viewModel.messages.isEmpty)
        #expect(voiceEngine.spokenTexts.isEmpty)
        #expect(interactionLog.lastProactiveSpeechAt == nil)
    }
}

/// Streams nothing and never finishes, holding Ghost in `.thinking` until the
/// consuming task is cancelled. Deliberately not `MockAIConversationService`,
/// whose reply lands on a timer — interrupting a race is not a test.
private final class HangingAIConversationService: AIConversationService, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    func streamResponse(to messages: [Message], healthContext: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // Retained, or the stream would finish the moment it deallocates.
            lock.lock()
            self.continuation = continuation
            lock.unlock()
        }
    }
}

/// Listens without ever producing a transcript, so interrupting a proactive
/// opener doesn't immediately kick off a second AI request and reopen the race
/// this test is trying to close.
@MainActor
private final class SilentVoiceEngine: VoiceEngine {
    private(set) var spokenTexts: [String] = []

    func startListening() -> AsyncThrowingStream<VoiceEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func stopListening() {}

    func speak(_ text: String) async throws {
        spokenTexts.append(text)
    }

    func stopSpeaking() {}
}

/// Polls a condition until it's true or a short timeout elapses — used
/// because the ViewModel's work runs on a detached `Task` triggered by
/// `micTapped()`.
@MainActor
private func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: () -> Bool
) async throws {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
}
