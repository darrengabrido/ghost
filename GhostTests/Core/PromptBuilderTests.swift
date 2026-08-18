@testable import Ghost
import Testing

struct PromptBuilderTests {
    @Test
    func systemPromptFoldsInHealthContextWhenProvided() {
        let prompt = PromptBuilder.systemPrompt(healthContext: "about 6.5 hours of sleep last night.")

        #expect(prompt.contains("about 6.5 hours of sleep last night."))
        #expect(prompt.contains("never recite the raw numbers"))
    }

    @Test
    func systemPromptOmitsHealthSectionWhenContextIsNil() {
        let prompt = PromptBuilder.systemPrompt()

        #expect(!prompt.contains("health patterns"))
    }

    @Test
    func systemPromptOmitsHealthSectionWhenContextIsEmpty() {
        let prompt = PromptBuilder.systemPrompt(healthContext: "")

        #expect(!prompt.contains("health patterns"))
    }
}
