@preconcurrency import ApplicationServices
import AppKit
import Foundation
import IOKit.hid
import os.log

private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "PermissionSetup")

/// Free function usable as a C function pointer for the test event tap.
/// Simply passes events through — we only need the tap to be created to prove
/// that Input Monitoring is granted.
private func testTapCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    Unmanaged.passUnretained(event)
}

/// Drives the first-launch permission setup screen.
/// Both Accessibility and Input Monitoring are required for keyboard blocking.
@MainActor
final class PermissionSetupViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false

    /// True when the user has manually confirmed they granted Input Monitoring
    /// but the system detection still can't pick it up (common with ad-hoc signed builds).
    @Published var userConfirmedInputMonitoring = false

    /// True once both Accessibility and Input Monitoring are granted (or user-confirmed).
    var canProceed: Bool {
        accessibilityGranted && (inputMonitoringGranted || userConfirmedInputMonitoring)
    }

    /// Whether to show the manual override option.
    /// Appears after the user has had time to grant the permission but detection fails.
    @Published private(set) var showManualOverride = false

    // MARK: - Private

    private var pollTask: Task<Void, Never>?
    private var overrideTimerTask: Task<Void, Never>?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        refresh()
    }

    // MARK: - Actions

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        SystemSettingsLink.accessibility.open()
        startPolling()
    }

    func requestInputMonitoring() {
        // Trigger the system consent dialog for Input Monitoring.
        CGRequestListenEventAccess()
        SystemSettingsLink.inputMonitoring.open()
        startPolling()
        startOverrideTimer()
    }

    /// Reveal the app in Finder so the user can drag it into the Input Monitoring "+" dialog.
    func revealAppInFinder() {
        let appURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([appURL])
    }

    func manualRefresh() {
        refresh()
    }

    /// The user manually confirms they have granted Input Monitoring.
    /// Used when macOS detection is unreliable (ad-hoc signed builds).
    func confirmInputMonitoringGranted() {
        logger.info("User manually confirmed Input Monitoring is granted.")
        userConfirmedInputMonitoring = true
    }

    /// Called when the user taps "Continue".
    func completeSetup() {
        stopPolling()
        overrideTimerTask?.cancel()
        settings.setupCompleted = true
    }

    func skipSetup() {
        stopPolling()
        overrideTimerTask?.cancel()
        settings.setupCompleted = true
    }

    // MARK: - Polling

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Manual Override Timer

    /// Shows the manual "I've already granted this" option after 10 seconds,
    /// in case the automated detection can't pick up the permission.
    private func startOverrideTimer() {
        overrideTimerTask?.cancel()
        overrideTimerTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.showManualOverride = true
            }
        }
    }

    // MARK: - Detection

    private func refresh() {
        accessibilityGranted = AXIsProcessTrusted()

        // Try multiple detection methods — Input Monitoring is notoriously
        // hard to detect reliably for ad-hoc signed builds.
        let detected = checkInputMonitoringGranted()
        if detected && !inputMonitoringGranted {
            logger.info("Input Monitoring detected as granted.")
        }
        inputMonitoringGranted = detected
    }

    private func checkInputMonitoringGranted() -> Bool {
        // Method 1: Try creating a test listenOnly event tap.
        // This is the most reliable runtime check because it directly tests
        // whether the system will allow us to tap events.
        if checkInputMonitoringViaTestEventTap() {
            logger.debug("Input Monitoring detected via test event tap.")
            return true
        }

        // Method 2: CGPreflightListenEventAccess() — the official API.
        // May not update in real-time for running processes on some macOS versions.
        if CGPreflightListenEventAccess() {
            logger.debug("Input Monitoring detected via CGPreflightListenEventAccess.")
            return true
        }

        // Method 3: Try seizing a HID keyboard device.
        if checkInputMonitoringViaHIDSeize() {
            logger.debug("Input Monitoring detected via HID seize.")
            return true
        }

        // Method 4: Check if built-in mouse/pointer devices are accessible.
        if checkInputMonitoringViaHIDOpen() {
            logger.debug("Input Monitoring detected via HID open.")
            return true
        }

        logger.debug("Input Monitoring NOT detected by any method.")
        return false
    }

    /// Try creating a temporary listenOnly CGEvent tap.
    /// If the system allows creating it, Input Monitoring is granted.
    /// The tap is immediately destroyed after the test.
    private func checkInputMonitoringViaTestEventTap() -> Bool {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback = testTapCallback as CGEventTapCallBack

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else {
            return false
        }

        // Tap created successfully — Input Monitoring is granted.
        // Immediately tear it down, we only needed the creation test.
        CFMachPortInvalidate(tap)
        return true
    }

    private func checkInputMonitoringViaHIDSeize() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Keyboard,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openStatus == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        var granted = false
        for device in devices {
            let status = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
            if status == kIOReturnSuccess {
                IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
                granted = true
                break
            }
            if status == IOReturn(kIOReturnExclusiveAccess) {
                granted = true
                break
            }
        }

        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return granted
    }

    private func checkInputMonitoringViaHIDOpen() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matchingList: [[String: Any]] = [
            [kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Mouse],
            [kIOHIDPrimaryUsagePageKey as String: kHIDPage_GenericDesktop,
             kIOHIDPrimaryUsageKey as String: kHIDUsage_GD_Pointer],
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingList as CFArray)
        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openStatus == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return false
        }

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []
        let hasBuiltIn = devices.contains { device in
            let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? ""
            return ["SPI", "I2C", "spi", "i2c"].contains(transport)
        }

        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        return hasBuiltIn
    }
}
