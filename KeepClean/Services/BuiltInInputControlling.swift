import Foundation

protocol BuiltInInputControlling: Actor {
    func prepareMonitoring() async
    func availabilitySummary() async -> String
    func lock(target: BuiltInInputTarget) async throws -> InputLockLease
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
