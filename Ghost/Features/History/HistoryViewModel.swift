import Foundation

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var conversations: [ConversationRecord] = []
    var errorMessage: String?

    private let conversationStore: ConversationStore

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
