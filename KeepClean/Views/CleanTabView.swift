import SwiftUI

struct CleanTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroPanel

                if let remainingTimedLockSeconds = model.remainingTimedLockSeconds {
                    countdownPanel(remainingTimedLockSeconds)
                }

                actionPanel

                if let autoStartCountdown = model.autoStartCountdownSecondsRemaining {
                    autoStartPanel(autoStartCountdown)
                }

                safetyPanel
            }
        }
    }

    private var heroPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.sky) {
            KeepCleanSectionEyebrow(text: "Built-in cleaning")
            Text("Pick the safest cleaning mode for this moment.")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(KeepCleanPalette.ink)

            Text(model.statusMessage)
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.72))

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KeepCleanPalette.warning)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(KeepCleanPalette.warning.opacity(0.10))
                    )
            }
        }
    }

    private var actionPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.amber) {
            KeepCleanSectionEyebrow(text: "Actions")

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    keyboardActionCard
                    fullCleanActionCard
                }

                VStack(spacing: 16) {
                    keyboardActionCard
                    fullCleanActionCard
                }
            }
        }
    }

    private var keyboardActionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Keyboard only", systemImage: "keyboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Spacer()
                KeepCleanStatusPill(
                    text: model.activeSession?.target == .keyboard ? "Keyboard locked" : "Trackpad stays live",
                    tint: model.activeSession?.target == .keyboard ? KeepCleanPalette.sky : KeepCleanPalette.success
                )
            }

            Text("Best when you want immediate control while keeping the built-in trackpad active for recovery.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))

            Button {
                Task {
                    await model.toggleKeyboardLock()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.keyboardButtonTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Built-in trackpad remains available")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(KeepCleanActionButtonStyle(tint: KeepCleanPalette.sky))
            .disabled(!model.canTriggerKeyboardAction)
            .accessibilityIdentifier("clean.disableKeyboard")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fullCleanActionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Full clean", systemImage: "sparkles.rectangle.stack")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Spacer()
                KeepCleanStatusPill(
                    text: "\(model.settings.fullCleanDurationSeconds)s auto-release",
                    tint: KeepCleanPalette.amber
                )
            }

            Text("Use the helper-owned timed lock when you need a strict cleaning window for both the keyboard and trackpad.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))

            Button {
                Task {
                    await model.startTimedFullClean()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.fullCleanButtonTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Strict timer with automatic recovery")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(KeepCleanActionButtonStyle(tint: KeepCleanPalette.warning))
            .disabled(!model.canTriggerTimedAction)
            .accessibilityIdentifier("clean.disableKeyboardAndTrackpad")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func autoStartPanel(_ seconds: Int) -> some View {
        KeepCleanPanel(accent: KeepCleanPalette.amber) {
            KeepCleanSectionEyebrow(text: "Launch countdown")
            Text("Keyboard disabling in \(seconds) seconds.")
                .font(.title2.weight(.bold))
                .foregroundStyle(KeepCleanPalette.ink)
                .accessibilityIdentifier("clean.autoStartCountdown")

            Text("Use the trackpad to cancel before the keyboard-only lock begins.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))

            Button("Cancel Auto-Start") {
                model.cancelAutoStart()
            }
            .buttonStyle(.borderedProminent)
            .tint(KeepCleanPalette.ink)
            .accessibilityIdentifier("clean.cancelAutoStart")
        }
    }

    private func countdownPanel(_ remainingTimedLockSeconds: Int) -> some View {
        KeepCleanPanel(accent: KeepCleanPalette.warning) {
            KeepCleanSectionEyebrow(text: "Timed session")
            HStack(alignment: .bottom, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full clean active")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(KeepCleanPalette.ink)

                    Text("Keyboard and trackpad will come back automatically.")
                        .font(.subheadline)
                        .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))
                }

                Spacer()

                Text("\(remainingTimedLockSeconds)s")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(KeepCleanPalette.warning)
            }
        }
    }

    private var safetyPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Safety")
            Text("KeepClean always favors recovery over cleverness.")
                .font(.title3.weight(.bold))
                .foregroundStyle(KeepCleanPalette.ink)

            VStack(alignment: .leading, spacing: 10) {
                safetyRow(symbol: "hand.point.up.left.fill", text: "Keyboard-only mode keeps the built-in trackpad active so you can re-enable it.")
                safetyRow(symbol: "timer", text: "Full clean mode always restores the keyboard and trackpad automatically.")
                safetyRow(symbol: "wifi.slash", text: "The app stays offline. Links only open when you tap the About tab buttons.")
            }
        }
    }

    private func safetyRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(KeepCleanPalette.sky)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.72))
        }
    }
}
