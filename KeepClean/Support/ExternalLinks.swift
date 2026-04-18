import Foundation

enum ExternalLink: CaseIterable {
    case donation
    case repository
    case profile

    var url: URL {
        switch self {
        case .donation:
            URL(string: "https://buymeacoffee.com/adhamhaithameid")!
        case .repository:
            URL(string: "https://github.com/adhamhaithameid/keep-clean")!
        case .profile:
            URL(string: "https://github.com/adhamhaithameid")!
        }
    }
}
