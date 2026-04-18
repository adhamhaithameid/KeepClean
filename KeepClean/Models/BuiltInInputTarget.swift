import Foundation

enum BuiltInInputTarget: String, Codable, Equatable, Sendable {
    case keyboard
    case trackpad
    case keyboardAndTrackpad

    var buttonTitle: String {
        switch self {
        case .keyboard:
            "Disable Keyboard"
        case .trackpad:
            "Disable Trackpad"
        case .keyboardAndTrackpad:
            "Disable Keyboard + Trackpad"
        }
    }
}
