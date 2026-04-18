import Foundation

enum LockOwner: String, Codable, Equatable, Sendable {
    case app
    case helper
}

struct LockSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let target: BuiltInInputTarget
    let owner: LockOwner
    let startedAt: Date
    let endsAt: Date?

    init(
        id: UUID = UUID(),
        target: BuiltInInputTarget,
        owner: LockOwner,
        startedAt: Date,
        endsAt: Date?
    ) {
        self.id = id
        self.target = target
        self.owner = owner
        self.startedAt = startedAt
        self.endsAt = endsAt
    }
}
