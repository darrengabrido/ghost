import Foundation
import os

/// Thin wrapper around `os.Logger` so call sites don't need to know the
/// subsystem string. Categories should map roughly to `Core/` subfolders.
enum Log {
    static let voice = Logger(subsystem: subsystem, category: "voice")
    static let ai = Logger(subsystem: subsystem, category: "ai")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let health = Logger(subsystem: subsystem, category: "health")
    static let presence = Logger(subsystem: subsystem, category: "presence")

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.oaktreehouse.ghost"
}
