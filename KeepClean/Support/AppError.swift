import Foundation

enum KeepCleanError: LocalizedError {
    case helperMissing
    case devicesUnavailable
    case keyboardUnavailable
    case trackpadUnavailable
    case permissionDenied(String)
    case seizeFailed(String)
    case invalidHelperArguments

    var errorDescription: String? {
        switch self {
        case .helperMissing:
            "The timed cleaning helper is missing from the app bundle."
        case .devicesUnavailable:
            "KeepClean couldn't find the built-in keyboard and trackpad yet. If macOS asks for approval, please allow access and try again."
        case .keyboardUnavailable:
            "KeepClean couldn't find the built-in keyboard."
        case .trackpadUnavailable:
            "KeepClean couldn't find the built-in trackpad."
        case .permissionDenied(let details):
            "macOS denied input access. \(details)"
        case .seizeFailed(let details):
            "KeepClean couldn't disable the built-in input device. \(details)"
        case .invalidHelperArguments:
            "The helper process received an invalid request."
        }
    }
}
