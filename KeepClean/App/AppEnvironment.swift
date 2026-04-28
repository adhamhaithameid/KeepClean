import Foundation

enum AppEnvironment {
    @MainActor
    static func makeViewModel() -> AppViewModel {
        let overrides = LaunchOverrides.current
        let userDefaults: UserDefaults

        if overrides.useMockInputController {
            let suiteName = "KeepClean.UITests"
            let defaults = UserDefaults(suiteName: suiteName) ?? .standard
            defaults.removePersistentDomain(forName: suiteName)
            userDefaults = defaults
        } else {
            userDefaults = .standard
        }

        let settings = AppSettings(userDefaults: userDefaults)
        // In UI test mode, bypass the permission setup gate so tests go directly
        // to the main tab UI without needing real TCC permissions.
        if overrides.useMockInputController {
            settings.setupCompleted = true
        }
        let inputController: any BuiltInInputControlling = overrides.useMockInputController
            ? MockBuiltInInputController()
            : LiveBuiltInInputController()
        let linkOpener: any LinkOpening = overrides.useMockInputController
            ? NoOpLinkOpener()
            : WorkspaceLinkOpener()

        let model = AppViewModel(
            settings: settings,
            inputController: inputController,
            helperLauncher: HelperProcessLauncher(),
            linkOpener: linkOpener,
            launchOverrides: overrides
        )
        // In UI test mode, force permissions to "granted" so that:
        // 1. The setup gate stays bypassed (resetSetupIfPermissionsRevoked won't re-show setup).
        // 2. The Clean tab doesn't show permission banners.
        if overrides.useMockInputController {
            model.setPermissionsForTesting(accessibility: true, inputMonitoring: true)
        }
        return model
    }
}
