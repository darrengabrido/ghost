import Foundation
import SwiftData

/// The persisted form of a conversation — distinct from `Message`, which
/// is the lightweight in-memory model the Conversation feature works with.
@Model
final class ConversationRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var transcript: String

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, transcript: String) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.transcript = transcript
    }
}
