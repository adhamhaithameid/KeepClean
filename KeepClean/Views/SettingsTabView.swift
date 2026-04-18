import SwiftUI

struct SettingsTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 30, weight: .bold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Keyboard + Trackpad Duration")
                    .font(.headline)
                Stepper(value: $settings.fullCleanDurationSeconds, in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds) {
                    Text("\(settings.fullCleanDurationSeconds) seconds")
                        .font(.title3.weight(.semibold))
                }
            }

            Toggle(isOn: $settings.autoStartKeyboardDisableOnLaunch) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start keyboard disable after opening the app")
                        .font(.headline)
                    Text("KeepClean will show a 3-second countdown first so you can cancel it with the trackpad.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Safety")
                    .font(.headline)
                Text("Keyboard-only mode never disables the built-in trackpad.")
                Text("Full clean mode always auto-recovers after the selected duration.")
                Text("KeepClean stays offline. The only links it opens are the About tab buttons in your default browser.")
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
