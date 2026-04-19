import SwiftUI

struct SettingsTabView: View {
    @ObservedObject var settings: AppSettings
    let openPrivacyAndSecurity: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Duration setting
            KeepCleanPanel {
                HStack(alignment: .firstTextBaseline) {
                    Text("Full Clean Duration")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KeepCleanPalette.ink)

                    Spacer()

                    Text("\(settings.fullCleanDurationSeconds)s")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(KeepCleanPalette.ink)
                        .accessibilityIdentifier("settings.durationValue")
                }

                Stepper(
                    "How long keyboard + trackpad stay disabled",
                    value: $settings.fullCleanDurationSeconds,
                    in: AppSettings.minimumDurationSeconds...AppSettings.maximumDurationSeconds
                )
                .font(.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .accessibilityIdentifier("settings.durationStepper")
            }

            // Auto-start toggle
            KeepCleanPanel {
                Toggle(isOn: $settings.autoStartKeyboardDisableOnLaunch) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-start on launch")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)

                        Text("Disables the keyboard 3 seconds after opening the app")
                            .font(.caption)
                            .foregroundStyle(KeepCleanPalette.mutedInk)
                    }
                }
                .accessibilityIdentifier("settings.autoStartToggle")
            }

            // Permissions shortcut
            KeepCleanPanel {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Permissions")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)

                        Text("Open macOS Privacy & Security settings")
                            .font(.caption)
                            .foregroundStyle(KeepCleanPalette.mutedInk)
                    }

                    Spacer()

                    Button {
                        openPrivacyAndSecurity()
                    } label: {
                        Label("Open", systemImage: "arrow.up.forward.square")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("settings.openPrivacyAndSecurity")
                }
            }

            Spacer()
        }
    }
}
