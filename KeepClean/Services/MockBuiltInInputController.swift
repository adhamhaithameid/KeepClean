import Foundation

actor MockBuiltInInputController: BuiltInInputControlling {
    func prepareMonitoring() async {}

    func availabilitySummary() async -> String {
        "Mock input controller ready for previews and UI tests."
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        InputLockLease(target: target, retainedObjects: [NSObject()])
    }
}
