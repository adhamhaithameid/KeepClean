import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var onWillTerminate: (() -> Void)?
    @MainActor var onSleep: (() -> Void)?
    @MainActor var onWake: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // #11: observe Mac sleep/wake to auto-end sessions
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(
            self, selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(
            self, selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        onWillTerminate?()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        if !flag {
            sender.windows.first?.makeKeyAndOrderFront(self)
            sender.activate(ignoringOtherApps: true)
        }
        return true
    }

    // MARK: - Sleep / Wake (#11)
    // NSWorkspace sleep notifications always arrive on the main thread.
    // Use assumeIsolated to call the @MainActor closures without crossing isolation.

    @objc private func handleSleep(_ note: Notification) {
        MainActor.assumeIsolated { onSleep?() }
    }

    @objc private func handleWake(_ note: Notification) {
        MainActor.assumeIsolated { onWake?() }
    }
}
