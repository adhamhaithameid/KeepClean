import Foundation

@main
struct LogicChecks {
    static func main() {
        let defaults = UserDefaults(suiteName: "KeepClean.LogicChecks")!
        defaults.removePersistentDomain(forName: "KeepClean.LogicChecks")

        let settings = AppSettings(userDefaults: defaults)
        precondition(settings.fullCleanDurationSeconds == 60)
        precondition(settings.autoStartKeyboardDisableOnLaunch == false)

        settings.fullCleanDurationSeconds = 999
        precondition(settings.fullCleanDurationSeconds == 180)

        settings.autoStartKeyboardDisableOnLaunch = true
        precondition(AppSettings(userDefaults: defaults).autoStartKeyboardDisableOnLaunch == true)

        let keyboardSnapshot = HIDDeviceSnapshot(
            id: 1,
            primaryUsage: .keyboard,
            isBuiltIn: true,
            transport: .spi,
            productName: "Apple Internal Keyboard / Trackpad"
        )
        precondition(BuiltInDeviceMatcher.role(for: keyboardSnapshot) == .keyboard)

        let trackpadSnapshot = HIDDeviceSnapshot(
            id: 2,
            primaryUsage: .mouse,
            isBuiltIn: true,
            transport: .spi,
            productName: "Apple Internal Keyboard / Trackpad"
        )
        precondition(BuiltInDeviceMatcher.role(for: trackpadSnapshot) == .trackpad)

        let request = HelperLaunchRequest(target: .keyboardAndTrackpad, durationSeconds: 60, startedAt: Date(timeIntervalSince1970: 100))
        let encoded = try! JSONEncoder().encode(request)
        let decoded = try! JSONDecoder().decode(HelperLaunchRequest.self, from: encoded)
        precondition(decoded == request)

        var coordinator = LockStateCoordinator(clock: TestClock(now: Date(timeIntervalSince1970: 10)))
        let manual = coordinator.beginManual(target: .keyboard, owner: .app)
        precondition(manual.endsAt == nil)
        let timed = coordinator.beginTimed(target: .keyboardAndTrackpad, durationSeconds: 20, owner: .helper)
        precondition(timed.endsAt == Date(timeIntervalSince1970: 30))
        coordinator.clear()
        precondition(coordinator.currentSession == nil)

        print("Logic checks passed.")
    }
}
