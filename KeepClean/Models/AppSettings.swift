import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let defaultDurationSeconds = 60
    static let minimumDurationSeconds = 15
    static let maximumDurationSeconds = 180

    private enum Keys {
        static let duration = "fullCleanDurationSeconds"
        static let autoStart = "autoStartKeyboardDisableOnLaunch"
        static let setupCompleted = "permissionSetupCompleted"
    }

    private let userDefaults: UserDefaults

    @Published var fullCleanDurationSeconds: Int {
        didSet {
            let clamped = Self.clamp(fullCleanDurationSeconds)
            if fullCleanDurationSeconds != clamped {
                fullCleanDurationSeconds = clamped
                return
            }
            userDefaults.set(clamped, forKey: Keys.duration)
        }
    }

    @Published var autoStartKeyboardDisableOnLaunch: Bool {
        didSet {
            userDefaults.set(autoStartKeyboardDisableOnLaunch, forKey: Keys.autoStart)
        }
    }

    /// Set to true after the user completes the first-launch permission setup.
    @Published var setupCompleted: Bool {
        didSet {
            userDefaults.set(setupCompleted, forKey: Keys.setupCompleted)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let duration = userDefaults.object(forKey: Keys.duration) as? Int ?? Self.defaultDurationSeconds
        self.fullCleanDurationSeconds = Self.clamp(duration)
        self.autoStartKeyboardDisableOnLaunch = userDefaults.object(forKey: Keys.autoStart) as? Bool ?? false
        self.setupCompleted = userDefaults.object(forKey: Keys.setupCompleted) as? Bool ?? false

        userDefaults.set(self.fullCleanDurationSeconds, forKey: Keys.duration)
        userDefaults.set(self.autoStartKeyboardDisableOnLaunch, forKey: Keys.autoStart)
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, minimumDurationSeconds), maximumDurationSeconds)
    }
}
