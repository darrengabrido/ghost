@testable import Ghost
import Testing

struct TranscriptCleanerTests {
    @Test
    func collapsesWhitespaceAndCapitalizes() {
        let cleaned = TranscriptCleaner.clean("  hello   there  ", isFinal: false)
        #expect(cleaned == "Hello there")
    }

    @Test
    func stripsFillerWordsOnlyWhenFinal() {
        let partial = TranscriptCleaner.clean("um hello uh there", isFinal: false)
        let final = TranscriptCleaner.clean("um hello uh there", isFinal: true)

        #expect(partial == "Um hello uh there")
        #expect(final == "Hello there")
    }

    @Test
    func doesNotStripWordsThatContainFillerSubstrings() {
        let cleaned = TranscriptCleaner.clean("bring an umbrella", isFinal: true)
        #expect(cleaned == "Bring an umbrella")
    }

    @Test
    func emptyInputStaysEmpty() {
        #expect(TranscriptCleaner.clean("   ", isFinal: true) == "")
    }
}
