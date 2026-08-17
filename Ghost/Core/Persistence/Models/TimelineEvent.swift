import Foundation
import SwiftData

/// The shared shape every external data source normalizes into before
/// Ghost can reference it — health today, calendar and others later.
/// Deliberately generic (timestamp/type/payload) so adding a new source
/// means writing a normalizer, not changing persistence: `type` namespaces
/// the source (e.g. "health.steps") and `payload` is that source's own
/// JSON-encoded shape.
@Model
final class TimelineEvent {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var type: String
    var payload: String

    init(id: UUID = UUID(), timestamp: Date, type: String, payload: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.payload = payload
    }
}
