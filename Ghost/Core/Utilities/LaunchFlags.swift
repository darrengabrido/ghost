import Foundation

/// Command-line flags passed by the UI test bundle. Never present in a
/// normal launch, so every branch guarded by these is dead code in the
/// shipping app.
enum LaunchFlags {
    static let uiTesting = "--ui-testing"

    /// True when the app was launched by `ScreenshotTests`.
    static let isUITesting = ProcessInfo.processInfo.arguments.contains(uiTesting)
}
