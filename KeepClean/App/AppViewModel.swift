import Foundation
import Observation

@MainActor
@Observable
final class AppViewModel {
    let settings: AppSettings

    var selectedTab: AppTab = .clean
    var activeSession: LockSession?
    var errorMessage: String?
    var statusMessage = "Preparing built-in input detection…"
    var remainingTimedLockSeconds: Int?
    var autoStartCountdownSecondsRemaining: Int?

    private let inputController: any BuiltInInputControlling
    private let helperLauncher: HelperProcessLauncher
    private let linkOpener: any LinkOpening
    private let launchOverrides: LaunchOverrides

    private var lockCoordinator = LockStateCoordinator()
    private var manualKeyboardLease: InputLockLease?
    private var mockTimedLease: InputLockLease?
    private var helperProcess: Process?
    private var timedCountdownTask: Task<Void, Never>?
    private var autoStartTask: Task<Void, Never>?
    private var didHandleInitialLaunch = false

    init(
        settings: AppSettings,
        inputController: any BuiltInInputControlling,
        helperLauncher: HelperProcessLauncher,
        linkOpener: any LinkOpening,
        launchOverrides: LaunchOverrides
    ) {
        self.settings = settings
        self.inputController = inputController
        self.helperLauncher = helperLauncher
        self.linkOpener = linkOpener
        self.launchOverrides = launchOverrides
    }

    var keyboardButtonTitle: String {
        manualKeyboardLease == nil ? "Disable Keyboard" : "Re-enable Keyboard"
    }

    var fullCleanButtonTitle: String {
        "Disable Keyboard + Trackpad for \(settings.fullCleanDurationSeconds) Seconds"
    }

    var hasActiveTimedSession: Bool {
        activeSession?.target == .keyboardAndTrackpad
    }

    var canTriggerKeyboardAction: Bool {
        activeSession == nil || activeSession?.target == .keyboard
    }

    var canTriggerTimedAction: Bool {
        activeSession == nil
    }

    func handleInitialAppearance() {
        guard !didHandleInitialLaunch else {
            return
        }

        didHandleInitialLaunch = true

        Task {
            await inputController.prepareMonitoring()
            statusMessage = await inputController.availabilitySummary()
        }

        if launchOverrides.forceAutoStartOn || settings.autoStartKeyboardDisableOnLaunch {
            beginAutoStartCountdown()
        }
    }

    func handleAppTermination() {
        timedCountdownTask?.cancel()
        autoStartTask?.cancel()

        Task {
            await manualKeyboardLease?.release()
            await mockTimedLease?.release()
        }

        helperProcess = nil
        manualKeyboardLease = nil
        mockTimedLease = nil
    }

    func toggleKeyboardLock() async {
        errorMessage = nil
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil

        if let manualKeyboardLease {
            await manualKeyboardLease.release()
            self.manualKeyboardLease = nil
            lockCoordinator.clear()
            activeSession = nil
            statusMessage = await inputController.availabilitySummary()
            return
        }

        do {
            let lease = try await inputController.lock(target: .keyboard)
            manualKeyboardLease = lease
            activeSession = lockCoordinator.beginManual(target: .keyboard, owner: .app)
            statusMessage = "Keyboard disabled. The built-in trackpad stays active so you can re-enable it."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = await inputController.availabilitySummary()
        }
    }

    func startTimedFullClean() async {
        guard activeSession == nil else {
            return
        }

        errorMessage = nil
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil

        if launchOverrides.useMockInputController {
            do {
                let lease = try await inputController.lock(target: .keyboardAndTrackpad)
                mockTimedLease = lease
                let session = lockCoordinator.beginTimed(
                    target: .keyboardAndTrackpad,
                    durationSeconds: settings.fullCleanDurationSeconds,
                    owner: .helper
                )
                activeSession = session
                startTimedCountdown(until: session.endsAt, releaseMockLeaseOnCompletion: true)
                statusMessage = "Keyboard and trackpad disabled for cleaning."
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }

        do {
            let request = HelperLaunchRequest(
                target: .keyboardAndTrackpad,
                durationSeconds: settings.fullCleanDurationSeconds,
                startedAt: Date()
            )
            let process = try helperLauncher.launch(request: request)
            helperProcess = process
            let session = lockCoordinator.beginTimed(
                target: .keyboardAndTrackpad,
                durationSeconds: settings.fullCleanDurationSeconds,
                owner: .helper
            )
            activeSession = session
            statusMessage = "Keyboard and trackpad disabled for cleaning."
            startTimedCountdown(until: session.endsAt, releaseMockLeaseOnCompletion: false)

            process.terminationHandler = { [weak self] process in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.helperProcess = nil
                    if process.terminationStatus != 0, self.remainingTimedLockSeconds != nil {
                        self.errorMessage = "The cleaning helper exited early."
                        self.finishTimedSession()
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = await inputController.availabilitySummary()
        }
    }

    func cancelAutoStart() {
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = nil
        statusMessage = "Auto-start canceled. You can trigger keyboard cleaning manually."
    }

    func open(_ link: ExternalLink) {
        linkOpener.open(link.url)
    }

    private func beginAutoStartCountdown() {
        autoStartTask?.cancel()
        autoStartCountdownSecondsRemaining = 3
        statusMessage = "Auto-start will disable the keyboard in a moment."

        autoStartTask = Task { [weak self] in
            guard let self else { return }

            for remaining in stride(from: 3, through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.autoStartCountdownSecondsRemaining = remaining
                }
                try? await Task.sleep(for: .seconds(1))
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.autoStartCountdownSecondsRemaining = nil
            }
            await self.toggleKeyboardLock()
        }
    }

    private func startTimedCountdown(until endDate: Date?, releaseMockLeaseOnCompletion: Bool) {
        timedCountdownTask?.cancel()

        guard let endDate else {
            return
        }

        remainingTimedLockSeconds = secondsUntil(endDate)

        timedCountdownTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                let remaining = self.secondsUntil(endDate)
                await MainActor.run {
                    self.remainingTimedLockSeconds = remaining
                }

                if remaining <= 0 {
                    if releaseMockLeaseOnCompletion {
                        await self.mockTimedLease?.release()
                        await MainActor.run {
                            self.mockTimedLease = nil
                        }
                    }

                    await MainActor.run {
                        self.finishTimedSession()
                    }
                    return
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func finishTimedSession() {
        timedCountdownTask?.cancel()
        remainingTimedLockSeconds = nil
        helperProcess = nil
        lockCoordinator.clear()
        activeSession = nil
        statusMessage = "Built-in input is available again."
    }

    private func secondsUntil(_ endDate: Date) -> Int {
        max(Int(ceil(endDate.timeIntervalSinceNow)), 0)
    }
}
