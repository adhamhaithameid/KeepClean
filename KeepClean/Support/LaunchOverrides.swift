import Foundation

struct LaunchOverrides {
    let useMockInputController: Bool
    let forceAutoStartOn: Bool

    static var current: LaunchOverrides {
        let arguments = ProcessInfo.processInfo.arguments
        return LaunchOverrides(
            useMockInputController: arguments.contains("UITEST_MOCK_INPUT"),
            forceAutoStartOn: arguments.contains("UITEST_AUTOSTART_ON")
        )
    }
}
