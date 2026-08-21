import Foundation
@testable import Ghost
import Testing

/// Titling rules for saved conversations. These matter because Ghost can now
/// open a conversation itself (`SpeakingDecision`), so the first message in a
/// saved array is no longer guaranteed to be the user's.
@MainActor
struct ConversationStoreTests {
    @Test
    func titleComesFromTheUsersFirstTurnWhenGhostOpened() async throws {
        let store = InMemoryConversationStore()

        try await store.save([
            Message(speaker: .ghost, text: "There you are. It's been a few days."),
            Message(speaker: .user, text: "yeah, I was travelling for work"),
            Message(speaker: .ghost, text: "Anywhere good?")
        ])

        let records = try await store.fetchAll()
        #expect(records.count == 1)
        #expect(records.first?.title == "yeah, I was travelling for work")
    }

    @Test
    func titleFallsBackToTheOpenerWhenTheUserNeverReplied() async throws {
        let store = InMemoryConversationStore()

        try await store.save([
            Message(speaker: .ghost, text: "There you are. It's been a few days.")
        ])

        #expect(try await store.fetchAll().first?.title == "There you are. It's been a few days.")
    }

    @Test
    func titleStillComesFromTheFirstTurnOfAUserLedConversation() async throws {
        let store = InMemoryConversationStore()

        try await store.save([
            Message(speaker: .user, text: "how far did I run this morning"),
            Message(speaker: .ghost, text: "About 5k.")
        ])

        #expect(try await store.fetchAll().first?.title == "how far did I run this morning")
    }

    @Test
    func savingNothingStoresNothing() async throws {
        let store = InMemoryConversationStore()

        try await store.save([])

        #expect(try await store.fetchAll().isEmpty)
    }
}
