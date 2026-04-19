import Foundation
import XCTest
@testable import KeepClean

@MainActor
final class AppViewModelTests: XCTestCase {
    func testHandleInitialAppearanceStartsMonitoringOnlyOnce() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        model.handleInitialAppearance()
        model.handleInitialAppearance()

        try await waitFor {
            await controller.prepareCallCount() == 1
        }
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testToggleKeyboardLockStartsAndStopsManualSession() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        await model.toggleKeyboardLock()

        XCTAssertEqual(model.activeSession?.target, .keyboard)
        XCTAssertTrue(model.isKeyboardLocked)
        XCTAssertFalse(model.canStartTimedClean)
        let lockedTargetsAfterStart = await controller.recordedTargets()
        XCTAssertEqual(lockedTargetsAfterStart, [.keyboard])

        await model.toggleKeyboardLock()

        XCTAssertNil(model.activeSession)
        XCTAssertFalse(model.isKeyboardLocked)
        XCTAssertEqual(model.statusMessage, "Built-in input ready.")
    }

    func testToggleKeyboardLockSurfacesPermissionErrors() async {
        let controller = TestBuiltInInputController(
            availability: "Built-in input ready.",
            nextLockError: KeepCleanError.permissionDenied("Allow access.")
        )
        let model = makeModel(inputController: controller)

        await model.toggleKeyboardLock()

        XCTAssertNil(model.activeSession)
        XCTAssertNotNil(model.toastMessage)
        XCTAssertTrue(model.toastIsError)
        XCTAssertTrue(model.canToggleKeyboard)
    }

    func testToggleKeyboardLockCancelsAutoStartCountdown() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        model.handleInitialAppearance()
        XCTAssertEqual(model.autoStartCountdownSecondsRemaining, 3)

        await model.toggleKeyboardLock()

        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertEqual(model.activeSession?.target, .keyboard)
    }

    func testTimedFullCleanStartsSessionUsingConfiguredDuration() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.fullCleanDurationSeconds = 15
        let model = makeModel(settings: settings, inputController: controller)

        await model.startTimedFullClean()

        XCTAssertEqual(model.activeSession?.target, .keyboardAndTrackpad)
        XCTAssertEqual(model.activeSession?.owner, .app)
        XCTAssertNotNil(model.remainingTimedLockSeconds)
        XCTAssertLessThanOrEqual(model.remainingTimedLockSeconds ?? 0, 15)
        XCTAssertGreaterThan(model.remainingTimedLockSeconds ?? 0, 0)
        let lockedTargets = await controller.recordedTargets()
        XCTAssertEqual(lockedTargets, [.keyboardAndTrackpad])

        model.handleAppTermination()
    }

    func testTimedFullCleanFailureShowsToast() async {
        let controller = TestBuiltInInputController(
            availability: "Built-in input ready.",
            nextLockError: KeepCleanError.devicesUnavailable
        )
        let model = makeModel(inputController: controller)

        await model.startTimedFullClean()

        XCTAssertNil(model.activeSession)
        XCTAssertNotNil(model.toastMessage)
        XCTAssertTrue(model.toastIsError)
    }

    func testTimedFullCleanIgnoredWhileAnotherSessionIsActive() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        await model.toggleKeyboardLock()
        let lockedTargetsBeforeSecondAction = await controller.recordedTargets()

        await model.startTimedFullClean()

        XCTAssertEqual(model.activeSession?.target, .keyboard)
        let lockedTargetsAfterSecondAction = await controller.recordedTargets()
        XCTAssertEqual(lockedTargetsBeforeSecondAction, lockedTargetsAfterSecondAction)
    }

    func testCancelAutoStartClearsCountdown() {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        model.handleInitialAppearance()
        XCTAssertEqual(model.autoStartCountdownSecondsRemaining, 3)

        model.cancelAutoStart()

        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.statusMessage, "Auto-start canceled.")
    }

    func testAutoStartEventuallyLocksKeyboard() async throws {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        model.handleInitialAppearance()

        try await waitFor(timeoutNanoseconds: 5_000_000_000) {
            model.activeSession?.target == .keyboard
        }
        let lockedTargets = await controller.recordedTargets()
        XCTAssertEqual(lockedTargets, [.keyboard])

        model.handleAppTermination()
    }

    func testHandleAppTerminationClearsVisibleState() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let settings = makeSettings(testName: #function)
        settings.autoStartKeyboardDisableOnLaunch = true
        let model = makeModel(settings: settings, inputController: controller)

        await model.startTimedFullClean()
        model.handleInitialAppearance()

        model.handleAppTermination()

        XCTAssertNil(model.activeSession)
        XCTAssertNil(model.remainingTimedLockSeconds)
        XCTAssertNil(model.autoStartCountdownSecondsRemaining)
        XCTAssertNil(model.toastMessage)
        XCTAssertEqual(model.statusMessage, "KeepClean closed.")
    }

    func testOpenDelegatesToLinkOpener() {
        let opener = TestLinkOpener()
        let model = makeModel(linkOpener: opener)

        model.open(.repository)

        XCTAssertEqual(opener.openedURLs, [ExternalLink.repository.url])
    }

    func testOpenPrivacyAndSecurityOpensSettingsLink() {
        // openPrivacyAndSecurity() calls SystemSettingsLink.open() directly,
        // not through the link opener. Just verify it doesn't crash.
        let model = makeModel()
        model.openPrivacyAndSecurity()
    }

    func testCancelTimedSessionRestoresState() async {
        let controller = TestBuiltInInputController(availability: "Built-in input ready.")
        let model = makeModel(inputController: controller)

        await model.startTimedFullClean()
        XCTAssertNotNil(model.activeSession)

        await model.cancelTimedSession()

        XCTAssertNil(model.activeSession)
        XCTAssertNil(model.remainingTimedLockSeconds)
    }

    func testToastDismissal() {
        let model = makeModel()

        model.showToast("Hello", isError: false)
        XCTAssertEqual(model.toastMessage, "Hello")
        XCTAssertFalse(model.toastIsError)

        model.dismissToast()
        XCTAssertNil(model.toastMessage)
    }

    private func makeModel(
        settings: AppSettings? = nil,
        inputController: TestBuiltInInputController = TestBuiltInInputController(),
        helperLauncher: HelperProcessLauncher = HelperProcessLauncher(helperURLProvider: { nil }),
        linkOpener: TestLinkOpener = TestLinkOpener(),
        launchOverrides: LaunchOverrides = LaunchOverrides(useMockInputController: false, forceAutoStartOn: false, forceTimedFullCleanOn: false)
    ) -> AppViewModel {
        let model = AppViewModel(
            settings: settings ?? makeSettings(testName: #function),
            inputController: inputController,
            helperLauncher: helperLauncher,
            linkOpener: linkOpener,
            launchOverrides: launchOverrides
        )
        // In tests, bypass system permission checks so we can test locking logic.
        model.hasAccessibility = true
        model.hasInputMonitoring = true
        return model
    }

    private func makeSettings(testName: String) -> AppSettings {
        let defaults = UserDefaults(suiteName: testName)!
        defaults.removePersistentDomain(forName: testName)
        return AppSettings(userDefaults: defaults)
    }

    private func makeExecutableScript(contents: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let scriptURL = directory.appendingPathComponent("helper.sh")
        try contents.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return scriptURL
    }

    private func waitFor(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () async -> Bool
    ) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for condition.")
    }
}

private actor TestBuiltInInputController: BuiltInInputControlling {
    private var prepareCalls = 0
    private var lockedTargets: [BuiltInInputTarget] = []
    private let availability: String
    private let nextLockError: Error?

    init(
        availability: String = "Built-in input ready.",
        nextLockError: Error? = nil
    ) {
        self.availability = availability
        self.nextLockError = nextLockError
    }

    func prepareMonitoring() async {
        prepareCalls += 1
    }

    func availabilitySummary() async -> String {
        availability
    }

    func lock(target: BuiltInInputTarget) async throws -> InputLockLease {
        if let nextLockError {
            throw nextLockError
        }

        lockedTargets.append(target)
        return InputLockLease(target: target, retainedObjects: [NSObject()])
    }

    func prepareCallCount() -> Int {
        prepareCalls
    }

    func recordedTargets() -> [BuiltInInputTarget] {
        lockedTargets
    }
}

private final class TestLinkOpener: LinkOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}
