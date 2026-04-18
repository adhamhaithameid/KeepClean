import XCTest
@testable import KeepClean

final class AppSettingsTests: XCTestCase {
    func testDefaultSettingsUseExpectedValues() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settings = AppSettings(userDefaults: defaults)

        XCTAssertEqual(settings.fullCleanDurationSeconds, 60)
        XCTAssertFalse(settings.autoStartKeyboardDisableOnLaunch)
    }

    func testDurationClampsAndPersists() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settings = AppSettings(userDefaults: defaults)
        settings.fullCleanDurationSeconds = 999

        XCTAssertEqual(settings.fullCleanDurationSeconds, 180)
        XCTAssertEqual(AppSettings(userDefaults: defaults).fullCleanDurationSeconds, 180)
    }

    func testAutoStartPersists() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settings = AppSettings(userDefaults: defaults)
        settings.autoStartKeyboardDisableOnLaunch = true

        XCTAssertTrue(AppSettings(userDefaults: defaults).autoStartKeyboardDisableOnLaunch)
    }
}
