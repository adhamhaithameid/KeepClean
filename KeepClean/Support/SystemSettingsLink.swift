import Foundation

enum SystemSettingsLink {
    case privacyAndSecurity

    var url: URL {
        switch self {
        case .privacyAndSecurity:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!
        }
    }
}
