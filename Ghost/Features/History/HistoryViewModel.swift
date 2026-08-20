import Foundation

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var conversations: [ConversationRecord] = []
    var searchText: String = ""
    var errorMessage: String?

    private let conversationStore: ConversationStore

    var filteredConversations: [ConversationRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return conversations }
        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.transcript.localizedCaseInsensitiveContains(query)
        }
    }

    init(conversationStore: ConversationStore) {
        self.conversationStore = conversationStore
    }

    func load() async {
        do {
            conversations = try await conversationStore.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ record: ConversationRecord) async {
        do {
            try await conversationStore.delete(record)
            conversations.removeAll { $0.id == record.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
