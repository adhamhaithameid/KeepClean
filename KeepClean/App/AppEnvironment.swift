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
        let inputController: any BuiltInInputControlling = overrides.useMockInputController
            ? MockBuiltInInputController()
            : LiveBuiltInInputController()
        let linkOpener: any LinkOpening = overrides.useMockInputController
            ? NoOpLinkOpener()
            : WorkspaceLinkOpener()

        return AppViewModel(
            settings: settings,
            inputController: inputController,
            helperLauncher: HelperProcessLauncher(),
            linkOpener: linkOpener,
            launchOverrides: overrides
        )
    }
}
