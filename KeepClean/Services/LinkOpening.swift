import AppKit
import Foundation

protocol LinkOpening {
    func open(_ url: URL)
}

struct WorkspaceLinkOpener: LinkOpening {
    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

struct NoOpLinkOpener: LinkOpening {
    func open(_ url: URL) {}
}
