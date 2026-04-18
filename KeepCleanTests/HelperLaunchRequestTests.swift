import XCTest
@testable import KeepClean

final class HelperLaunchRequestTests: XCTestCase {
    func testRoundTripsThroughJSON() throws {
        let request = HelperLaunchRequest(
            target: .keyboardAndTrackpad,
            durationSeconds: 60,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(HelperLaunchRequest.self, from: data)

        XCTAssertEqual(decoded.target, .keyboardAndTrackpad)
        XCTAssertEqual(decoded.durationSeconds, 60)
        XCTAssertEqual(decoded.startedAt, request.startedAt)
    }
}
