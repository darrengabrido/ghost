import Testing
@testable import Ghost

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
            preferences: InMemoryUserPreferencesStore()
        )

        viewModel.micTapped()

        try await waitUntil { viewModel.orbState == .idle }

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages.first?.speaker == .user)
        #expect(viewModel.messages.last?.speaker == .ghost)
        #expect(try await store.fetchAll().count == 1)
    }

    @Test
    func micTappedWhileSpeakingInterruptsWhenEnabled() async throws {
        let voiceEngine = MockVoiceEngine()
        voiceEngine.holdSpeakUntilStopped = true
        let viewModel = ConversationViewModel(
            voiceEngine: voiceEngine,
            aiConversationService: MockAIConversationService(reply: "hi there"),
            conversationStore: InMemoryConversationStore(),
            preferences: InMemoryUserPreferencesStore(isVoiceInterruptionEnabled: true)
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
            preferences: InMemoryUserPreferencesStore(isVoiceInterruptionEnabled: false)
        )

        viewModel.micTapped()
        try await waitUntil { viewModel.orbState == .speaking }

        viewModel.micTapped()

        #expect(voiceEngine.stopSpeakingCallCount == 0)
        #expect(viewModel.orbState == .speaking)
        voiceEngine.stopSpeaking()
    }
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
