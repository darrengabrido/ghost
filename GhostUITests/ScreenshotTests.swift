import XCTest

/// Captures every redesigned screen as a PNG attachment.
///
/// Ghost is an atmospheric app whose whole point is how it looks, and until
/// CI started running there was no way to see a single frame of it. These
/// aren't assertions about appearance — nothing here can tell you the design
/// is *good*. They exist so a human can look at the result without a Mac.
///
/// Launched with `--ui-testing` so the app builds its mock environment: the
/// live one reaches HealthKit on the conversation screen and drops a system
/// permission sheet over the shot.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureEveryScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 30))
        capture(app, named: "01-onboarding")

        app.buttons["Continue"].tap()

        // The empty composition: spirit centred, before anything is said.
        XCTAssertTrue(app.staticTexts["Tap to speak"].waitForExistence(timeout: 30))
        capture(app, named: "02-conversation-idle")

        app.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 15))
        capture(app, named: "03-history")

        goBack(in: app)

        XCTAssertTrue(app.staticTexts["Tap to speak"].waitForExistence(timeout: 15))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 15))
        capture(app, named: "04-settings")
    }

    /// A short settle before each shot: the atmosphere animates continuously,
    /// and a frame grabbed mid-transition shows the transition rather than
    /// the screen.
    private func capture(_ app: XCUIApplication, named name: String) {
        Thread.sleep(forTimeInterval: 1.5)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func goBack(in app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists {
            backButton.tap()
        }
    }
}
