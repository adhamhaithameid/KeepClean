import Foundation

enum BuiltInInputTarget: String, Codable, Equatable, Sendable {
    case keyboard
    case trackpad
    case keyboardAndTrackpad

    var includesKeyboard: Bool {
        self == .keyboard || self == .keyboardAndTrackpad
    }

    var includesTrackpad: Bool {
        self == .trackpad || self == .keyboardAndTrackpad
    }

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
