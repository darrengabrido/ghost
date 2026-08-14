import XCTest

final class GhostUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingShowsContinueButton() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
    }

    func testTappingContinueNavigatesToConversation() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Tap to speak"].waitForExistence(timeout: 5))
    }
}
