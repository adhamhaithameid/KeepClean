import AppKit
import SwiftUI

// MARK: - Menu Bar Controller (#15)
// Optional NSStatusItem. Enabled via Settings > "Show in menu bar".

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private(set) var isActive = false

    func setup(model: AppViewModel) {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let url   = Bundle.main.url(forResource: "brand-mark", withExtension: "png"),
               let nsImg = NSImage(contentsOf: url) {
                nsImg.size = NSSize(width: 16, height: 16)
                nsImg.isTemplate = false
                button.image = nsImg
            } else {
                button.title = "🧹"
            }
            button.toolTip = "KeepClean"
            button.action  = #selector(MenuBarProxy.showWindow)
            button.target  = MenuBarProxy.shared
        }

        let menu = NSMenu()
        let showItem = NSMenuItem(
            title: "Show KeepClean",
            action: #selector(MenuBarProxy.showWindow),
            keyEquivalent: ""
        )
        showItem.target = MenuBarProxy.shared
        menu.addItem(showItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit KeepClean",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        statusItem?.menu = menu

        isActive = true
    }

    func teardown() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
        isActive = false
    }

    func updateState(sessionActive: Bool) {
        statusItem?.button?.toolTip = sessionActive
            ? "KeepClean — Session active"
            : "KeepClean"
    }
}

// MARK: - Obj-C bridgeable proxy

// @unchecked Sendable is safe here because MenuBarProxy only touches
// NSApp and NSWindow from the main thread (called by NSMenu/button action).
private final class MenuBarProxy: NSObject, @unchecked Sendable {
    static let shared = MenuBarProxy()

    @objc func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
