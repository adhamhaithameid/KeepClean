import Foundation

struct LockStateCoordinator {
    private let clock: any TimeProviding
    private(set) var currentSession: LockSession?

    init(clock: any TimeProviding = SystemClock()) {
        self.clock = clock
    }

    @discardableResult
    mutating func beginManual(target: BuiltInInputTarget, owner: LockOwner) -> LockSession {
        let session = LockSession(target: target, owner: owner, startedAt: clock.now, endsAt: nil)
        currentSession = session
        return session
    }

    @discardableResult
    mutating func beginTimed(target: BuiltInInputTarget, durationSeconds: Int, owner: LockOwner) -> LockSession {
        let session = LockSession(
            target: target,
            owner: owner,
            startedAt: clock.now,
            endsAt: clock.now.addingTimeInterval(TimeInterval(durationSeconds))
        )
        currentSession = session
        return session
    }

    mutating func clear() {
        currentSession = nil
    }
}
