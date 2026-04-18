import XCTest
@testable import KeepClean

final class BuiltInDeviceMatcherTests: XCTestCase {
    func testBuiltInSPIKeyboardMatchesKeyboardRole() {
        let snapshot = HIDDeviceSnapshot(
            id: 1,
            primaryUsage: .keyboard,
            isBuiltIn: true,
            transport: .spi,
            productName: "Apple Internal Keyboard / Trackpad"
        )

        XCTAssertEqual(BuiltInDeviceMatcher.role(for: snapshot), .keyboard)
    }

    func testBuiltInSPIMouseMatchesTrackpadRole() {
        let snapshot = HIDDeviceSnapshot(
            id: 2,
            primaryUsage: .mouse,
            isBuiltIn: true,
            transport: .spi,
            productName: "Apple Internal Keyboard / Trackpad"
        )

        XCTAssertEqual(BuiltInDeviceMatcher.role(for: snapshot), .trackpad)
    }

    func testExternalKeyboardDoesNotMatch() {
        let snapshot = HIDDeviceSnapshot(
            id: 3,
            primaryUsage: .keyboard,
            isBuiltIn: false,
            transport: .usb,
            productName: "External Keyboard"
        )

        XCTAssertNil(BuiltInDeviceMatcher.role(for: snapshot))
    }
}
