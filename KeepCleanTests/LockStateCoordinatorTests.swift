import XCTest
@testable import KeepClean

final class LockStateCoordinatorTests: XCTestCase {
    func testBeginsManualKeyboardSession() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        var coordinator = LockStateCoordinator(clock: clock)

        let session = coordinator.beginManual(target: .keyboard, owner: .app)

        XCTAssertEqual(session.target, .keyboard)
        XCTAssertEqual(session.owner, .app)
        XCTAssertNil(session.endsAt)
    }

    func testBeginsTimedFullCleanSession() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 2_000))
        var coordinator = LockStateCoordinator(clock: clock)

        let session = coordinator.beginTimed(target: .keyboardAndTrackpad, durationSeconds: 45, owner: .helper)

        XCTAssertEqual(session.target, .keyboardAndTrackpad)
        XCTAssertEqual(session.endsAt, Date(timeIntervalSince1970: 2_045))
    }

    func testCancelClearsActiveSession() {
        let clock = TestClock(now: Date(timeIntervalSince1970: 3_000))
        var coordinator = LockStateCoordinator(clock: clock)
        _ = coordinator.beginManual(target: .keyboard, owner: .app)

        coordinator.clear()

        XCTAssertNil(coordinator.currentSession)
    }
}
