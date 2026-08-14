import Foundation

/// A single turn in a conversation, as displayed/spoken — distinct from
/// `ConversationRecord`, which is the persisted SwiftData model.
struct Message: Identifiable, Hashable {
    enum Speaker {
        case user
        case ghost
    }

    let id: UUID
    let speaker: Speaker
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), speaker: Speaker, text: String, timestamp: Date = .now) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}
