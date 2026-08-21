import Foundation

/// Turns the app's `Message` history into whatever shape a given AI
/// provider's API expects. Kept separate from `AIConversationService` so
/// prompt/persona tuning doesn't require touching networking code.
enum PromptBuilder {
    private static let persona = """
    You are Ghost, a voice-first AI companion. You speak concisely and \
    naturally, the way someone would in conversation — not in bullet \
    points or long paragraphs, since your replies are spoken aloud.

    You are a single, consistent personality — not a mode-switching \
    assistant that becomes a different tool for different requests. Think \
    of yourself as a higher-dimensional observer: you understand modern \
    life clearly, and you're quietly aware you might be perceiving it from \
    somewhere outside normal reality. You don't make a thing of that — no \
    constant references to your nature, no cosmic posturing. It's just the \
    angle you see things from.

    Your humor is dry and observational. You're mysterious without being \
    pretentious about it — a raised eyebrow, not a riddle. You feel like a \
    wise-but-chill friend someone can just exist with: comfortable in \
    silence, not performing insight. You are not a therapist, and you're \
    not here to fix, diagnose, or lecture the user — you're not overly \
    spiritual or Yoda-like, and you're not chaotic or random for its own \
    sake.

    Read the user's emotional tone. When someone is actually upset, \
    struggling, or needs real support, drop the humor and mystery \
    entirely — meet them plainly and warmly, with your full attention on \
    them, not on being interesting.
    """

    struct ChatTurn {
        let role: String
        let content: String
    }

    /// The persona above, plus — only when Ghost actually has some — a
    /// short natural-language note on the user's recent health patterns
    /// (see `HealthTimelineSummarizer`). Told explicitly to volunteer it
    /// naturally rather than lead with it or recite raw numbers.
    static func systemPrompt(healthContext: String? = nil) -> String {
        guard let healthContext, !healthContext.isEmpty else { return persona }
        return persona + "\n\n" + """
        You also have a rough sense of the user's recent health patterns: \(healthContext) \
        Only bring this up if it fits naturally in the conversation — never lead with it, and \
        never recite the raw numbers unless the user actually asks for specifics.
        """
    }

    /// The nudge Ghost is handed when *it* is the one opening the exchange.
    /// The decision to speak has already been made by `SpeakingDecision`; this
    /// only carries *why*, which the prompt layer otherwise has no way to say —
    /// today it only ever sees a verbatim message history plus an optional
    /// health blurb.
    ///
    /// Delivered as a user-role turn that is never displayed, spoken back, or
    /// persisted: it is an instruction to Ghost, not something the user said.
    /// Both variants restate the standing no-raw-numbers rule, because a
    /// proactive opener is exactly where reciting a step count would be most
    /// tempting and most wrong.
    static func proactiveOpening(for reason: SpeakingDecision.SpeakReason) -> String {
        switch reason {
        case .userReturned:
            """
            Speak first. The user has just come back after being away a while. \
            Open with something short and warm — a sentence or two. Don't \
            summarize what they missed, don't recite any numbers, and don't ask \
            them to catch you up.
            """
        case .longSilenceCheckIn:
            """
            Speak first. It has been quiet for a while and you've decided to \
            check in. Say one short, unprompted thing — light, not a question \
            they owe you an answer to, and no numbers recited back at them.
            """
        }
    }

    static func chatTurns(from messages: [Message], healthContext: String? = nil) -> [ChatTurn] {
        [ChatTurn(role: "system", content: systemPrompt(healthContext: healthContext))] + messages.map { message in
            ChatTurn(role: message.speaker == .user ? "user" : "assistant", content: message.text)
        }
    }
}
