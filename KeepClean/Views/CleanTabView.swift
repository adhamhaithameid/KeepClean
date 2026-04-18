import SwiftUI

struct CleanTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                overviewPanel

                if let autoStartCountdown = model.autoStartCountdownSecondsRemaining {
                    autoStartPanel(autoStartCountdown)
                }

                if let remainingTimedLockSeconds = model.remainingTimedLockSeconds {
                    countdownPanel(remainingTimedLockSeconds)
                }

                actionsPanel
                safetyPanel
            }
        }
    }

    private var overviewPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Built-in inputs")
            Text("Clean your keyboard and trackpad without guessing.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(KeepCleanPalette.ink)

            Text(model.statusMessage)
                .font(.body)
                .foregroundStyle(KeepCleanPalette.mutedInk)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(KeepCleanPalette.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(KeepCleanPalette.orange.opacity(0.10))
                    )
            }
        }
    }

    private var actionsPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Actions")

            VStack(alignment: .leading, spacing: 10) {
                actionHeader(
                    title: "Disable Keyboard",
                    subtitle: "Keeps the built-in trackpad active so you can turn it back on.",
                    status: model.activeSession?.target == .keyboard ? "Keyboard disabled" : "Trackpad stays active",
                    tint: model.activeSession?.target == .keyboard ? KeepCleanPalette.blue : KeepCleanPalette.success
                )

                Button(model.keyboardButtonTitle) {
                    Task {
                        await model.toggleKeyboardLock()
                    }
                }
                .buttonStyle(KeepCleanActionButtonStyle(tint: KeepCleanPalette.blue))
                .disabled(!model.canTriggerKeyboardAction)
                .accessibilityIdentifier("clean.disableKeyboard")
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                actionHeader(
                    title: "Disable Keyboard + Trackpad",
                    subtitle: "Uses the helper process and always restores input after the timer ends.",
                    status: "\(model.settings.fullCleanDurationSeconds) second timer",
                    tint: KeepCleanPalette.orange
                )

                Button(model.fullCleanButtonTitle) {
                    Task {
                        await model.startTimedFullClean()
                    }
                }
                .buttonStyle(KeepCleanActionButtonStyle(tint: KeepCleanPalette.orange))
                .disabled(!model.canTriggerTimedAction)
                .accessibilityIdentifier("clean.disableKeyboardAndTrackpad")
            }
        }
    }

    private func autoStartPanel(_ seconds: Int) -> some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Auto-start")
            Text("Keyboard disable starts in \(seconds) seconds.")
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink)
                .accessibilityIdentifier("clean.autoStartCountdown")

            Text("Cancel now if you opened the app by mistake.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)

            Button("Cancel Auto-Start") {
                model.cancelAutoStart()
            }
            .buttonStyle(.borderedProminent)
            .tint(KeepCleanPalette.ink)
            .accessibilityIdentifier("clean.cancelAutoStart")
        }
    }

    private func countdownPanel(_ remainingTimedLockSeconds: Int) -> some View {
        KeepCleanPanel {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    KeepCleanSectionEyebrow(text: "Timed clean")
                    Text("Full clean is active.")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink)
                    Text("Keyboard and trackpad will return automatically.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                }

                Spacer()

                Text("\(remainingTimedLockSeconds)s")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(KeepCleanPalette.orange)
            }
        }
    }

    private var safetyPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Safety")

            VStack(alignment: .leading, spacing: 8) {
                safetyRow("Keyboard-only mode never disables the built-in trackpad.")
                safetyRow("Full clean mode always restores the keyboard and trackpad automatically.")
                safetyRow("KeepClean stays offline. Links only open when you use the About tab buttons.")
            }
        }
    }

    private func actionHeader(title: String, subtitle: String, status: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(KeepCleanPalette.ink)

                Spacer()

                KeepCleanStatusPill(text: status, tint: tint)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }

    private func safetyRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(KeepCleanPalette.blue)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
    }
}
