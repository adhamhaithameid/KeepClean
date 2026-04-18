import Foundation

enum HIDPrimaryUsage: String, Codable, Equatable, Sendable {
    case keyboard
    case mouse
    case touchPad
    case unknown
}

enum HIDTransportKind: String, Codable, Equatable, Sendable {
    case spi
    case i2c
    case usb
    case bluetooth
    case other
}

enum BuiltInInputRole: String, Equatable, Sendable {
    case keyboard
    case trackpad
}

struct HIDDeviceSnapshot: Identifiable, Equatable, Sendable {
    let id: UInt64
    let primaryUsage: HIDPrimaryUsage
    let isBuiltIn: Bool
    let transport: HIDTransportKind
    let productName: String
}

enum BuiltInDeviceMatcher {
    static func role(for snapshot: HIDDeviceSnapshot) -> BuiltInInputRole? {
        guard snapshot.isBuiltIn else {
            return nil
        }

        guard snapshot.transport == .spi || snapshot.transport == .i2c else {
            return nil
        }

        switch snapshot.primaryUsage {
        case .keyboard:
            return .keyboard
        case .mouse, .touchPad:
            return .trackpad
        case .unknown:
            return nil
        }
    }
}
