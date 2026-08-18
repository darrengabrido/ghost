import Foundation

/// Normalizes raw speech-to-text output into clean text ready to hand to
/// `AIConversationService`. Kept as a pure, standalone step so cleanup
/// rules can evolve (or be tuned per STT provider's quirks) without
/// touching audio capture or the recognition engine itself.
enum TranscriptCleaner {
    /// Filler words most STT engines transcribe literally. Matched as
    /// whole words only, so real words containing them (e.g. "um" inside
    /// "umbrella") are left alone.
    private static let fillerWords: Set<String> = ["um", "uh", "uhh", "umm", "erm", "hmm"]

    /// Cleans a transcript for display or hand-off. `isFinal` controls
    /// whether filler-word stripping runs — skipped for partial/live
    /// transcripts so the UI doesn't have text visibly vanish mid-utterance
    /// as the recognizer refines its guess.
    static func clean(_ text: String, isFinal: Bool) -> String {
        var result = collapseWhitespace(text)
        if isFinal {
            result = stripFillerWords(result)
        }
        return capitalizeFirstLetter(result)
    }

    private static func collapseWhitespace(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func stripFillerWords(_ text: String) -> String {
        text
            .split(separator: " ")
            .filter { !fillerWords.contains($0.lowercased().trimmingCharacters(in: .punctuationCharacters)) }
            .joined(separator: " ")
    }

    private static func capitalizeFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
