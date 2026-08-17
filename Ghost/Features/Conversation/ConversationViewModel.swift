import Foundation

@Observable
@MainActor
final class ConversationViewModel {
    private(set) var messages: [Message] = []
    private(set) var orbState: PulsingOrb.State = .idle
    private(set) var liveTranscript: String = ""
    private(set) var audioLevels: [CGFloat] = Array(repeating: 0, count: 24)
    var errorMessage: String?

    private let voiceEngine: VoiceEngine
    private let aiConversationService: AIConversationService
    private let conversationStore: ConversationStore
    private let preferences: UserPreferencesStore
    private let healthDataProvider: HealthDataProvider
    private let timelineStore: TimelineStore
    private var listenTask: Task<Void, Never>?
    private var healthContext: String?

    init(
        voiceEngine: VoiceEngine,
        aiConversationService: AIConversationService,
        conversationStore: ConversationStore,
        preferences: UserPreferencesStore,
        healthDataProvider: HealthDataProvider,
        timelineStore: TimelineStore
    ) {
        self.voiceEngine = voiceEngine
        self.aiConversationService = aiConversationService
        self.conversationStore = conversationStore
        self.preferences = preferences
        self.healthDataProvider = healthDataProvider
        self.timelineStore = timelineStore
    }

    /// Called once when the conversation screen appears. Syncs recent
    /// HealthKit data onto the shared timeline and summarizes it for later
    /// AI calls — silently does nothing if HealthKit is unavailable or
    /// permission was denied, and never blocks the UI on failure.
    func start() async {
        let sinceDate = Date.now.addingTimeInterval(-Self.healthLookback)
        let syncService = HealthTimelineSyncService(provider: healthDataProvider, timelineStore: timelineStore)
        _ = try? await syncService.sync(since: sinceDate)

        let recentEvents = (try? await timelineStore.recentEvents(since: sinceDate)) ?? []
        healthContext = HealthTimelineSummarizer.summarize(recentEvents)
    }

    private static let healthLookback: TimeInterval = 24 * 60 * 60

    func micTapped() {
        switch orbState {
        case .listening:
            stopListening()
        case .speaking:
            guard preferences.isVoiceInterruptionEnabled else { return }
            voiceEngine.stopSpeaking()
            startListening()
        case .idle:
            startListening()
        case .thinking:
            break
        }
    }

    private func startListening() {
        orbState = .listening
        liveTranscript = ""

        listenTask = Task {
            do {
                for try await event in voiceEngine.startListening() {
                    switch event {
                    case .partialTranscript(let text):
                        liveTranscript = text
                    case .amplitude(let levels):
                        audioLevels = levels
                    case .finalTranscript(let text):
                        liveTranscript = ""
                        await handleUserUtterance(text)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                orbState = .idle
            }
        }
    }

    private func stopListening() {
        listenTask?.cancel()
        listenTask = nil
        voiceEngine.stopListening()
        orbState = .idle
    }

    private func handleUserUtterance(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            orbState = .idle
            return
        }

        let userMessage = Message(speaker: .user, text: text)
        messages.append(userMessage)
        orbState = .thinking

        do {
            var reply = ""
            for try await token in aiConversationService.streamResponse(to: messages, healthContext: healthContext) {
                reply += token
            }

            let ghostMessage = Message(speaker: .ghost, text: reply)
            messages.append(ghostMessage)

            orbState = .speaking
            try await voiceEngine.speak(reply)

            try await conversationStore.save(messages)
        } catch {
            errorMessage = error.localizedDescription
        }

        if orbState == .speaking {
            orbState = .idle
        }
    }
}
