import SwiftUI

struct CleanTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Clean")
                .font(.system(size: 30, weight: .bold))

            Text(model.statusMessage)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                    )
            }

            if let autoStartCountdown = model.autoStartCountdownSecondsRemaining {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Keyboard disabling in \(autoStartCountdown) seconds.")
                        .font(.title3.weight(.semibold))
                        .accessibilityIdentifier("clean.autoStartCountdown")

                    Button("Cancel Auto-Start") {
                        model.cancelAutoStart()
                    }
                    .accessibilityIdentifier("clean.cancelAutoStart")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.yellow.opacity(0.15))
                )
            }

            VStack(spacing: 18) {
                Button(model.keyboardButtonTitle) {
                    Task {
                        await model.toggleKeyboardLock()
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle(backgroundColor: .blue))
                .disabled(!model.canTriggerKeyboardAction)
                .accessibilityIdentifier("clean.disableKeyboard")

                Button(model.fullCleanButtonTitle) {
                    Task {
                        await model.startTimedFullClean()
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle(backgroundColor: .orange))
                .disabled(!model.canTriggerTimedAction)
                .accessibilityIdentifier("clean.disableKeyboardAndTrackpad")
            }

            if let remainingTimedLockSeconds = model.remainingTimedLockSeconds {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full clean active")
                        .font(.title3.weight(.semibold))
                    Text("\(remainingTimedLockSeconds) seconds remaining")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
            }

            Text("Keyboard-only mode keeps the built-in trackpad active so you can always re-enable it. Full clean mode always restores the keyboard and trackpad automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    let backgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundColor.opacity(configuration.isPressed ? 0.82 : 1))
            )
    }
}
