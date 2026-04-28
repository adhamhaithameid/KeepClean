import XCTest

/// UI tests for KeepClean.
///
/// All tests use the UITEST_MOCK_INPUT launch argument so the app skips
/// real device access and jumps straight to the main tab UI
/// (setup is also bypassed via the ephemeral UserDefaults suite).
final class KeepCleanUITests: XCTestCase {

    // MARK: - Clean Tab

    func testCleanTabShowsKeyboardAndFullCleanCards() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        // Tab bar buttons — use this as the primary existence check
        XCTAssertTrue(window.buttons["tab.clean"].waitForExistence(timeout: 30))
        XCTAssertTrue(window.buttons["tab.settings"].exists)
        XCTAssertTrue(window.buttons["tab.about"].exists)

        // Action card buttons (identified by accessibility identifiers, not title)
        XCTAssertTrue(window.buttons["clean.disableKeyboard"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.buttons["clean.disableKeyboardAndTrackpad"].exists)
    }

    func testCleanTabKeyboardCardStaticText() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.clean"].waitForExistence(timeout: 30))
        window.buttons["tab.clean"].click()

        XCTAssertTrue(window.staticTexts["Keyboard Only"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.staticTexts["Full Clean"].exists)
    }

    func testCleanTabKeyboardCardSubtitleWhenIdle() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.clean"].waitForExistence(timeout: 30))

        // Idle subtitle text for the keyboard card
        XCTAssertTrue(window.staticTexts["Trackpad stays active"].waitForExistence(timeout: 5))
    }

    // MARK: - Settings Tab

    func testSettingsTabShowsDurationAndAutoStartControls() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.settings"].waitForExistence(timeout: 30))
        window.buttons["tab.settings"].click()

        // Duration value label (shows "60 seconds")
        XCTAssertTrue(window.staticTexts["60 seconds"].waitForExistence(timeout: 5))

        // Stepper
        XCTAssertTrue(window.steppers["Choose how long full clean stays active."].exists)

        // Auto-start toggle
        XCTAssertTrue(window.checkBoxes["Start keyboard disable after opening the app"].exists)
    }

    func testSettingsTabShowsPermissionsSection() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.settings"].waitForExistence(timeout: 30))
        window.buttons["tab.settings"].click()

        // Open Settings button
        XCTAssertTrue(window.buttons["settings.openPrivacyAndSecurity"].waitForExistence(timeout: 5))
    }

    // MARK: - Auto-start

    func testAutoStartCountdownCanBeCanceled() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MOCK_INPUT", "UITEST_AUTOSTART_ON"]
        app.launch()
        app.activate()

        let window = app.windows.element(boundBy: 0)

        let cancelButton = window.buttons["clean.cancelAutoStart"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 30))

        cancelButton.click()

        // After cancel, the countdown button should disappear
        XCTAssertFalse(cancelButton.waitForExistence(timeout: 3))
    }

    // MARK: - About Tab

    func testAboutTabShowsLinks() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.about"].waitForExistence(timeout: 30))
        window.buttons["tab.about"].click()

        XCTAssertTrue(window.buttons["about.repo"].waitForExistence(timeout: 5))
        XCTAssertTrue(window.buttons["about.donate"].exists)
        XCTAssertTrue(window.buttons["about.profile"].exists)
    }

    func testAboutTabShowsVersionText() {
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        XCTAssertTrue(window.buttons["tab.about"].waitForExistence(timeout: 30))
        window.buttons["tab.about"].click()

        let versionPredicate = NSPredicate(format: "label BEGINSWITH 'Version '")
        let versionLabel = window.staticTexts.matching(versionPredicate).firstMatch
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 5))
    }

    // MARK: - Permission Setup Screen

    func testPermissionSetupScreenNotShownWithMockInput() {
        // UITEST_MOCK_INPUT bypasses setup — confirm we're on the main tab UI.
        let app = launch()
        let window = app.windows.element(boundBy: 0)

        // The clean tab is visible, not the setup screen.
        XCTAssertTrue(window.buttons["tab.clean"].waitForExistence(timeout: 30))
        // The setup grant buttons should NOT be present
        XCTAssertFalse(window.buttons["setup.grantAccessibility"].exists)
    }

    // MARK: - Helpers

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_MOCK_INPUT")
        app.launch()
        app.activate()
        return app
    }
}
