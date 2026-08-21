import Foundation

@Observable
@MainActor
final class ConversationViewModel {
    private(set) var messages: [Message] = []
    private(set) var orbState: PulsingOrb.Phase = .idle
    private(set) var liveTranscript: String = ""
    private(set) var audioLevels: [CGFloat] = Array(repeating: 0, count: 24)
    var errorMessage: String?

    private let voiceEngine: VoiceEngine
    private let aiConversationService: AIConversationService
    private let conversationStore: ConversationStore
    private let preferences: UserPreferencesStore
    private let healthDataProvider: HealthDataProvider
    private let timelineStore: TimelineStore
    private let proactiveSpeechStateStore: ProactiveSpeechStateStore
    private var listenTask: Task<Void, Never>?
    private var healthContext: String?

    init(
        voiceEngine: VoiceEngine,
        aiConversationService: AIConversationService,
        conversationStore: ConversationStore,
        preferences: UserPreferencesStore,
        healthDataProvider: HealthDataProvider,
        timelineStore: TimelineStore,
        proactiveSpeechStateStore: ProactiveSpeechStateStore
    ) {
        self.voiceEngine = voiceEngine
        self.aiConversationService = aiConversationService
        self.conversationStore = conversationStore
        self.preferences = preferences
        self.healthDataProvider = healthDataProvider
        self.timelineStore = timelineStore
        self.proactiveSpeechStateStore = proactiveSpeechStateStore
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

        if case .speak(let reason) = evaluateSpeakingDecision(recentEvents: recentEvents) {
            await speakProactively(reason: reason)
        }
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

        // Evaluated against the interaction state from *before* this
        // exchange — `lastInteractionAt` isn't updated until after, or the
        // interaction cooldown below would always suppress this checkpoint,
        // since it runs moments after the exchange it would otherwise be
        // measured from.
        await checkForProactiveFollowUp()
        proactiveSpeechStateStore.lastInteractionAt = .now
    }

    private func checkForProactiveFollowUp() async {
        guard orbState == .idle else { return }
        let sinceDate = Date.now.addingTimeInterval(-Self.healthLookback)
        let recentEvents = (try? await timelineStore.recentEvents(since: sinceDate)) ?? []
        if case .speak(let reason) = evaluateSpeakingDecision(recentEvents: recentEvents) {
            await speakProactively(reason: reason)
        }
    }

    private func evaluateSpeakingDecision(recentEvents: [TimelineEvent]) -> SpeakingDecision.Outcome {
        SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: recentEvents,
                now: .now,
                lastInteractionAt: proactiveSpeechStateStore.lastInteractionAt,
                lastProactiveSpeechAt: proactiveSpeechStateStore.lastProactiveSpeechAt,
                quietHours: preferences.quietHours
            )
        )
    }

    /// Speaks unprompted. Gated on `orbState == .idle` unconditionally —
    /// `DefaultVoiceEngine` has no reentrancy guard of its own, so this must
    /// never fire while a listen/speak cycle is already in flight.
    private func speakProactively(reason: SpeakingDecision.SpeakReason) async {
        guard orbState == .idle else { return }
        proactiveSpeechStateStore.lastProactiveSpeechAt = .now

        // A seed turn, not a real user message: `streamResponse` requires a
        // non-empty history starting with a user turn, but there's no real
        // utterance to send here — Ghost is speaking first. Used only as
        // this call's wire payload; never appended to `messages` or
        // persisted, so History only ever shows Ghost's actual reply.
        let cue = Message(speaker: .user, text: cueText(for: reason))
        orbState = .thinking

        do {
            var reply = ""
            for try await token in aiConversationService.streamResponse(to: messages + [cue], healthContext: healthContext) {
                reply += token
            }

            guard !reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                orbState = .idle
                return
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

    private func cueText(for reason: SpeakingDecision.SpeakReason) -> String {
        switch reason {
        case .userReturned:
            return "The user just returned after being away for a while. Greet them warmly and briefly — don't recite data, just acknowledge them."
        case .longSilenceCheckIn:
            return "Something new has come in since you last spoke, and enough time has passed that it may be worth a brief, natural mention if it's actually worth bringing up."
        }
    }
}
