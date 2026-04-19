import SwiftUI

struct CleanTabView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Permission banner (always visible when permissions are missing)
            if !model.hasAccessibility {
                permissionBanner(
                    title: "Accessibility permission needed",
                    detail: "Required to disable the keyboard.",
                    buttonTitle: "Grant Accessibility",
                    action: { model.promptAccessibility() }
                )
                .padding(.bottom, 12)
            }

            if !model.hasInputMonitoring {
                permissionBanner(
                    title: "Input Monitoring permission needed",
                    detail: "Required for keyboard blocking to take effect.",
                    buttonTitle: "Grant Input Monitoring",
                    action: { model.promptInputMonitoring() }
                )
                .padding(.bottom, 12)
            }

            // Auto-start banner
            if let countdown = model.autoStartCountdownSecondsRemaining {
                autoStartBanner(countdown: countdown)
                    .padding(.bottom, 12)
            }

            // Timer overlay when timed session is active
            if model.isTimedSessionActive, let remaining = model.remainingTimedLockSeconds {
                timerDisplay(remaining: remaining)
                    .padding(.bottom, 16)
            }

            // Side-by-side action cards
            HStack(spacing: 14) {
                keyboardCard
                timedCleanCard
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            // Status bar at bottom
            statusBar
        }
        .onAppear {
            model.refreshPermissions()
        }
    }

    // MARK: - Permission Banner

    private func permissionBanner(
        title: String,
        detail: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()

            Button(buttonTitle) {
                action()
            }
            .font(.system(size: 12, weight: .semibold))
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                }
        }
    }

    // MARK: - Keyboard Card

    private var keyboardCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(model.isKeyboardLocked
                              ? KeepCleanPalette.blue.opacity(0.15)
                              : KeepCleanPalette.surface)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle()
                                .strokeBorder(model.isKeyboardLocked
                                              ? KeepCleanPalette.blue.opacity(0.4)
                                              : KeepCleanPalette.border, lineWidth: 1)
                        }

                    Image(systemName: model.isKeyboardLocked ? "keyboard.fill" : "keyboard")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(model.isKeyboardLocked ? KeepCleanPalette.blue : KeepCleanPalette.ink)
                }

                Text("Keyboard Only")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(model.isKeyboardLocked
                     ? "Disabled"
                     : "Trackpad stays active")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 18)
            .padding(.horizontal, 12)

            Spacer(minLength: 12)

            Button {
                Task { await model.toggleKeyboardLock() }
            } label: {
                Text(model.isKeyboardLocked ? "Re-enable" : "Disable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(model.isKeyboardLocked
                                  ? KeepCleanPalette.success
                                  : KeepCleanPalette.blue)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!model.canToggleKeyboard)
            .opacity(model.canToggleKeyboard ? 1 : 0.4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .accessibilityIdentifier("clean.disableKeyboard")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(model.isKeyboardLocked
                                      ? KeepCleanPalette.blue.opacity(0.4)
                                      : KeepCleanPalette.border, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .animation(.easeInOut(duration: 0.25), value: model.isKeyboardLocked)
    }

    // MARK: - Timed Clean Card

    private var timedCleanCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(model.isTimedSessionActive
                              ? KeepCleanPalette.orange.opacity(0.15)
                              : KeepCleanPalette.surface)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle()
                                .strokeBorder(model.isTimedSessionActive
                                              ? KeepCleanPalette.orange.opacity(0.4)
                                              : KeepCleanPalette.border, lineWidth: 1)
                        }

                    Image(systemName: model.isTimedSessionActive ? "lock.fill" : "lock.open")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(model.isTimedSessionActive ? KeepCleanPalette.orange : KeepCleanPalette.ink)
                }

                Text("Full Clean")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(model.isTimedSessionActive
                     ? "Locked"
                     : "Both for \(model.settings.fullCleanDurationSeconds)s")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 18)
            .padding(.horizontal, 12)

            Spacer(minLength: 12)

            Button {
                if model.isTimedSessionActive {
                    Task { await model.cancelTimedSession() }
                } else {
                    Task { await model.startTimedFullClean() }
                }
            } label: {
                Text(model.isTimedSessionActive ? "Re-enable" : "Disable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(model.isTimedSessionActive
                                  ? KeepCleanPalette.success
                                  : KeepCleanPalette.orange)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!model.canStartTimedClean && !model.isTimedSessionActive)
            .opacity(model.canStartTimedClean || model.isTimedSessionActive ? 1 : 0.4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .accessibilityIdentifier("clean.disableKeyboardAndTrackpad")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(model.isTimedSessionActive
                                      ? KeepCleanPalette.orange.opacity(0.4)
                                      : KeepCleanPalette.border, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .animation(.easeInOut(duration: 0.25), value: model.isTimedSessionActive)
    }

    // MARK: - Timer Display

    private func timerDisplay(remaining: Int) -> some View {
        let minutes = remaining / 60
        let seconds = remaining % 60
        let timeString = String(format: "%d:%02d", minutes, seconds)
        let progress = model.settings.fullCleanDurationSeconds > 0
            ? 1.0 - (Double(remaining) / Double(model.settings.fullCleanDurationSeconds))
            : 0.0

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(KeepCleanPalette.border.opacity(0.3), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        KeepCleanPalette.orange,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                Text(timeString)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(KeepCleanPalette.ink)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cleaning in progress")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)

                Text("Keyboard and trackpad are disabled.")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(KeepCleanPalette.orange.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(KeepCleanPalette.orange.opacity(0.2), lineWidth: 1)
                }
        }
        .transition(.opacity)
    }

    // MARK: - Auto-Start Banner

    private func autoStartBanner(countdown: Int) -> some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(KeepCleanPalette.blue)

            Text("Keyboard disable in \(countdown)...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KeepCleanPalette.ink)

            Spacer()

            Button("Cancel") {
                model.cancelAutoStart()
            }
            .font(.system(size: 12, weight: .medium))
            .accessibilityIdentifier("clean.cancelAutoStart")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(KeepCleanPalette.blue.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(KeepCleanPalette.blue.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(model.activeSession != nil ? KeepCleanPalette.orange : KeepCleanPalette.success)
                .frame(width: 6, height: 6)

            Text(model.statusMessage)
                .font(.system(size: 11))
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}
