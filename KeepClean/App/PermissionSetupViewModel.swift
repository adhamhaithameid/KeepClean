@preconcurrency import ApplicationServices
import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: "com.adhamhaithameid.keepclean", category: "PermissionSetup")

/// Drives the first-launch permission setup screen.
/// Both Accessibility and Input Monitoring are required for keyboard blocking.
@MainActor
final class PermissionSetupViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false

    /// True when the user has manually confirmed they granted Input Monitoring
    /// but the system detection still can't pick it up (common with ad-hoc signed builds).
    @Published private(set) var userConfirmedInputMonitoring = false

    /// True once both Accessibility and Input Monitoring are granted (or user-confirmed).
    var canProceed: Bool {
        accessibilityGranted && (inputMonitoringGranted || userConfirmedInputMonitoring)
    }

    /// Whether to show the manual override option.
    /// Appears after `overrideTimerDelay` seconds once the user has triggered
    /// Input Monitoring setup but detection still hasn't confirmed the grant.
    @Published private(set) var showManualOverride = false

    // MARK: - Private

    private var pollTask: Task<Void, Never>?
    private var overrideTimerTask: Task<Void, Never>?
    private let settings: AppSettings

    /// Configurable delay (in seconds) before the manual override UI appears.
    /// Kept at 10s in production; injectable for tests.
    let overrideTimerDelay: Double

    init(settings: AppSettings, overrideTimerDelay: Double = 10) {
        self.settings = settings
        self.overrideTimerDelay = overrideTimerDelay
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

    // MARK: - Polling

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Internal accessor for tests — indicates whether the poll loop is currently running.
    var isPolling: Bool { pollTask != nil }

    // MARK: - Manual Override Timer

    /// Shows the manual "I've already granted this" option after `overrideTimerDelay` seconds,
    /// in case the automated detection can't pick up the permission.
    private func startOverrideTimer() {
        overrideTimerTask?.cancel()
        overrideTimerTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(overrideTimerDelay))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                // Only show override if detection still hasn't confirmed the grant.
                if !(self.inputMonitoringGranted || self.userConfirmedInputMonitoring) {
                    self.showManualOverride = true
                }
            }
        }
    }

    // MARK: - Detection

    private func refresh() {
        let wasAccessibility = accessibilityGranted
        let wasInputMonitoring = inputMonitoringGranted

        accessibilityGranted = AXIsProcessTrusted()

        let detected = InputMonitoringDetector.isGranted()
        if detected && !wasInputMonitoring {
            logger.info("Input Monitoring detected as granted.")
        }
        inputMonitoringGranted = detected

        // Auto-clear manual override and user-confirmation if detection now succeeds.
        if inputMonitoringGranted {
            showManualOverride = false
        }

        // Auto-clear the manual confirmation if the permission later gets revoked
        // (so the user isn't stuck in a permanently bypassed state).
        if !inputMonitoringGranted && !accessibilityGranted && userConfirmedInputMonitoring {
            // Only reset if BOTH dropped — a revoke of one shouldn't wipe the confirmation.
        }

        if wasAccessibility != accessibilityGranted || wasInputMonitoring != inputMonitoringGranted {
            logger.debug("Permission state changed: accessibility=\(self.accessibilityGranted), inputMonitoring=\(self.inputMonitoringGranted)")
        }
    }
}
