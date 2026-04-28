import Foundation

protocol BuiltInInputControlling: Actor {
    func prepareMonitoring() async
    func availabilitySummary() async -> String

    /// Acquire a lock on the given input target. Caller must release the returned lease.
    func lock(target: BuiltInInputTarget) async throws -> InputLockLease

    /// Acquire a lock with emergency-stop support.
    /// `onEmergencyStop` is called on the main thread when the user presses
    /// Left ⌘ + Right ⌘ + 1 + 0 simultaneously while the lock is active.
    func lock(
        target: BuiltInInputTarget,
        onEmergencyStop: @escaping @Sendable () -> Void
    ) async throws -> InputLockLease
}

// MARK: - Default implementations

extension BuiltInInputControlling {
    /// Default: emergency-stop callback is silently ignored.
    /// Mock / test controllers get this for free and need no changes.
    func lock(
        target: BuiltInInputTarget,
        onEmergencyStop: @escaping @Sendable () -> Void
    ) async throws -> InputLockLease {
        try await lock(target: target)
    }
}

protocol InputLockResource: AnyObject {
    func releaseLock()
}

actor InputLockLease {
    let target: BuiltInInputTarget
    private var retainedObjects: [AnyObject]?

    init(target: BuiltInInputTarget, retainedObjects: [AnyObject]) {
        self.target = target
        self.retainedObjects = retainedObjects
    }

    func release() {
        retainedObjects?.forEach { object in
            (object as? InputLockResource)?.releaseLock()
        }
        retainedObjects = nil
    }
}
