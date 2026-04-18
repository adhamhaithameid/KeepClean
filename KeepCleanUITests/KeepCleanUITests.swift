import XCTest

final class KeepCleanUITests: XCTestCase {
    func testTabsAndPrimaryButtonsRender() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()

        XCTAssertTrue(app.buttons["tab.clean"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.settings"].exists)
        XCTAssertTrue(app.buttons["tab.about"].exists)
        XCTAssertTrue(app.buttons["clean.disableKeyboard"].exists)
        XCTAssertTrue(app.buttons["clean.disableKeyboardAndTrackpad"].exists)
    }

    func testAutoStartCountdownCanBeCanceled() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MOCK_INPUT", "UITEST_AUTOSTART_ON"]
        app.launch()

        XCTAssertTrue(app.staticTexts["clean.autoStartCountdown"].waitForExistence(timeout: 3))
        app.buttons["clean.cancelAutoStart"].click()
        XCTAssertFalse(app.staticTexts["clean.autoStartCountdown"].exists)
    }

    func testAboutTabShowsLinks() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()

        app.buttons["tab.about"].click()

        XCTAssertTrue(app.buttons["about.donate"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["about.repo"].exists)
        XCTAssertTrue(app.buttons["about.profile"].exists)
    }
}
