@testable import Ghost
import Foundation
import Testing

@MainActor
struct HistoryViewModelTests {
    @Test
    func filteredConversationsMatchesTitleOrTranscriptCaseInsensitively() async throws {
        let store = MockConversationStore()
        store.recordsToReturn = [
            ConversationRecord(title: "Morning run recap", transcript: "You: how far did I go\nGhost: 5k"),
            ConversationRecord(title: "Dinner plans", transcript: "You: what should I cook\nGhost: pasta"),
            ConversationRecord(title: "Late night", transcript: "You: tell me about the RUN streak\nGhost: nice"),
        ]

        let viewModel = HistoryViewModel(conversationStore: store)
        await viewModel.load()

        #expect(viewModel.filteredConversations.count == 3)

        viewModel.searchText = "run"
        #expect(viewModel.filteredConversations.map(\.title).sorted() == ["Late night", "Morning run recap"])

        viewModel.searchText = "pasta"
        #expect(viewModel.filteredConversations.map(\.title) == ["Dinner plans"])

        viewModel.searchText = "   "
        #expect(viewModel.filteredConversations.count == 3)

        viewModel.searchText = "nonexistent"
        #expect(viewModel.filteredConversations.isEmpty)
    }
}
