import Foundation

struct LaunchOverrides {
    let useMockInputController: Bool
    let forceAutoStartOn: Bool
    let forceTimedFullCleanOn: Bool

    init(
        useMockInputController: Bool,
        forceAutoStartOn: Bool,
        forceTimedFullCleanOn: Bool
    ) {
        self.useMockInputController = useMockInputController
        self.forceAutoStartOn = forceAutoStartOn
        self.forceTimedFullCleanOn = forceTimedFullCleanOn
    }

    init(arguments: [String]) {
        self.init(
            useMockInputController: arguments.contains("UITEST_MOCK_INPUT"),
            forceAutoStartOn: arguments.contains("UITEST_AUTOSTART_ON"),
            forceTimedFullCleanOn: arguments.contains("UITEST_FULL_CLEAN_ON")
        )
    }

    static var current: LaunchOverrides {
        LaunchOverrides(arguments: ProcessInfo.processInfo.arguments)
    }
}
