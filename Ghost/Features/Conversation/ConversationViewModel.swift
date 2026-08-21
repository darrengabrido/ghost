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
    private let interactionLog: InteractionLog
    private let quietHours: QuietHours?
    private var listenTask: Task<Void, Never>?
    private var healthContext: String?

    init(
        voiceEngine: VoiceEngine,
        aiConversationService: AIConversationService,
        conversationStore: ConversationStore,
        preferences: UserPreferencesStore,
        healthDataProvider: HealthDataProvider,
        timelineStore: TimelineStore,
        interactionLog: InteractionLog,
        quietHours: QuietHours? = .default
    ) {
        self.voiceEngine = voiceEngine
        self.aiConversationService = aiConversationService
        self.conversationStore = conversationStore
        self.preferences = preferences
        self.healthDataProvider = healthDataProvider
        self.timelineStore = timelineStore
        self.interactionLog = interactionLog
        self.quietHours = quietHours
    }

    /// Called once when the conversation screen appears. Syncs recent
    /// HealthKit data onto the shared timeline and summarizes it for later
    /// AI calls — silently does nothing if HealthKit is unavailable or
    /// permission was denied, and never blocks the UI on failure.
    ///
    /// Also the first of the two `SpeakingDecision` checkpoints: this is where
    /// `.userReturned` and `.longSilenceCheckIn` get their shot, with the
    /// timeline freshly synced and the orb guaranteed idle.
    func start() async {
        let sinceDate = Date.now.addingTimeInterval(-Self.healthLookback)
        let syncService = HealthTimelineSyncService(provider: healthDataProvider, timelineStore: timelineStore)
        _ = try? await syncService.sync(since: sinceDate)

        let recentEvents = (try? await timelineStore.recentEvents(since: sinceDate)) ?? []
        healthContext = HealthTimelineSummarizer.summarize(recentEvents)

        await considerSpeaking(given: recentEvents)
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
        interactionLog.recordInteraction(at: .now)
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

        // The second `SpeakingDecision` checkpoint — the natural pause a human
        // would use, for a signal that arrived *during* a conversation.
        //
        // Worth knowing before reading this as dead code: in v1 it suppresses
        // in essentially every real case. It runs moments after the user spoke,
        // so `lastInteractionAt` is roughly now and `interactionFloor` catches
        // it — which is scenario B, the correct behaviour, not a bug. It comes
        // alive the moment there is any re-evaluation that *isn't* triggered by
        // the user talking, which the staged v1 deliberately doesn't build.
        await considerSpeaking()
    }

    /// Gathers the snapshot `SpeakingDecision` needs and acts on its answer.
    ///
    /// - Parameter events: timeline events already in hand at the call site, so
    ///   the screen-appear checkpoint doesn't re-query the store moments after
    ///   `start()` just read it.
    private func considerSpeaking(given events: [TimelineEvent]? = nil) async {
        guard orbState == .idle else { return }

        let now = Date.now
        let recentEvents: [TimelineEvent]
        if let events {
            recentEvents = events
        } else {
            let sinceDate = now.addingTimeInterval(-Self.healthLookback)
            recentEvents = (try? await timelineStore.recentEvents(since: sinceDate)) ?? []
        }

        let outcome = SpeakingDecision.evaluate(
            SpeakingDecision.Input(
                recentTimelineEvents: recentEvents,
                now: now,
                lastInteractionAt: interactionLog.lastInteractionAt,
                lastProactiveSpeechAt: interactionLog.lastProactiveSpeechAt,
                quietHours: quietHours
            )
        )

        guard case .speak(let reason) = outcome else { return }
        await speakProactively(reason)
    }

    /// Ghost opening the exchange itself. Mirrors `handleUserUtterance`, with
    /// two deliberate differences: a failure stays silent rather than raising
    /// an alert for a request the user never made, and an unanswered opener
    /// isn't persisted on its own — it's already in `messages` and lands in
    /// History with the first real exchange, so a greeting nobody replied to
    /// doesn't become a conversation in the list.
    private func speakProactively(_ reason: SpeakingDecision.SpeakReason) async {
        guard orbState == .idle else { return }
        orbState = .thinking

        let nudge = Message(speaker: .user, text: PromptBuilder.proactiveOpening(for: reason))

        do {
            var reply = ""
            let stream = aiConversationService.streamResponse(to: messages + [nudge], healthContext: healthContext)
            for try await token in stream {
                reply += token
            }

            let spoken = reply.trimmingCharacters(in: .whitespacesAndNewlines)

            // The user may have tapped the mic while the reply was streaming.
            // This is the whole reentrancy guard v1 needs: `voiceEngine.speak`
            // is never reached from a state this method no longer owns, so a
            // proactive utterance can't yank the audio session out from under a
            // live recognition stream. No lock, no actor, no queue.
            if !spoken.isEmpty, orbState == .thinking {
                messages.append(Message(speaker: .ghost, text: spoken))
                orbState = .speaking
                try await voiceEngine.speak(spoken)
                interactionLog.recordProactiveSpeech(at: .now)
            }
        } catch {
            // Deliberately silent. An error alert for something the user never
            // asked for is worse than Ghost simply not speaking — the same
            // posture as the health sync in `start()`.
            Log.presence.error("Proactive speech failed: \(error.localizedDescription)")
        }

        if orbState == .thinking || orbState == .speaking {
            orbState = .idle
        }
    }
}
