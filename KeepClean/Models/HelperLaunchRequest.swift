import Foundation

struct HelperLaunchRequest: Codable, Equatable, Sendable {
    let target: BuiltInInputTarget
    let durationSeconds: Int
    let startedAt: Date
}
