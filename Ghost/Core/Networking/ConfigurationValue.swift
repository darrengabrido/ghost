import Foundation

enum ConfigurationValue {
    /// True when a plist/xcconfig value is empty, unsubstituted, or still
    /// the placeholder from `Secrets.xcconfig.example`.
    static func isPlaceholder(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let lowered = trimmed.lowercased()
        return lowered.hasPrefix("$(")
            || lowered.hasPrefix("replace-with-")
            || lowered.contains("example.com")
            || lowered.contains("your-key")
            || lowered.contains("your-anthropic")
    }
}
