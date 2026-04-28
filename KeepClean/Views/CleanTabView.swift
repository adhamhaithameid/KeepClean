import AppKit
import SwiftUI

struct CleanTabView: View {
    @ObservedObject var model: AppViewModel
    private let accent = KeepCleanPalette.teal
    @State private var keyboardShimmer = false
    @State private var timedShimmer = false

    var body: some View {
        VStack(spacing: 12) {

            // Permission banners — slide in from top (#15)
            if !model.hasAccessibility {
                permissionBanner(
                    title: "Accessibility permission needed",
                    detail: "Required to disable the keyboard.",
                    buttonTitle: "Grant Access",
                    identifier: "clean.grantAccessibility",
                    action: { model.promptAccessibility() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !model.hasInputMonitoring {
                permissionBanner(
                    title: "Input Monitoring needed",
                    detail: "Required for keyboard blocking to take effect.",
                    buttonTitle: "Grant Access",
                    identifier: "clean.grantInputMonitoring",
                    action: { model.promptInputMonitoring() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Undo window (#13)
            if let mode = model.undoPendingMode {
                undoBanner(mode: mode)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // State-driven content (#27)
            switch model.displayState {
            case .countdown(let n):
                autoStartBanner(countdown: n)
                    .transition(.move(edge: .top).combined(with: .opacity))

            case .timedActive(let remaining):
                timerDisplay(remaining: remaining)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))

            default:
                EmptyView()
            }

            // Action cards — glassmorphism (#1), shimmer (#2), confetti overlay (#7)
            ZStack {
                // Equal-height cards — expand to fill available vertical space
                HStack(alignment: .top, spacing: 12) {
                    keyboardCard
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    timedCleanCard
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Confetti burst overlay (#7)
                ConfettiBurst(active: model.showConfetti)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // ⌘K shortcut
            .keyboardShortcut("k", modifiers: .command)
            // ⌘R repeat last session (#14)
            .background(
                Button("") { model.repeatLastSession() }
                    .keyboardShortcut("r", modifiers: .command)
                    .opacity(0).allowsHitTesting(false)
            )

            // FAQ (#18)
            if model.allPermissionsGranted {
                faqDisclosure
                    .transition(.opacity)
            }

            // Status bar (#9)
            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 4)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.displayState)
        .animation(.spring(response: 0.3), value: model.undoPendingMode != nil)
        .onChange(of: model.isKeyboardLocked) { locked in
            if locked {
                keyboardShimmer = true
                model.updateDockBadge(active: true)  // #8
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { keyboardShimmer = false }
            } else {
                model.updateDockBadge(active: model.isTimedSessionActive)  // #8
            }
        }
        .onChange(of: model.isTimedSessionActive) { active in
            if active {
                timedShimmer = true
                model.updateDockBadge(active: true)  // #8
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { timedShimmer = false }
            } else {
                model.updateDockBadge(active: model.isKeyboardLocked)  // #8
            }
        }
    }

    // MARK: - Permission Banner (#15)

    private func permissionBanner(
        title: String,
        detail: String,
        buttonTitle: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Text(detail)
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()

            Button(buttonTitle, action: action)
                .font(.system(size: 12, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(accent)
                .accessibilityIdentifier(identifier)
        }
        .padding(11)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
        .accessibilityHint("Double-tap to open System Settings.")
    }

    // MARK: - Undo Banner (#13)

    private func undoBanner(mode: AppSettings.CleanMode) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(accent)
            Text(mode == .keyboard ? "Keyboard disabled" : "Full clean started")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KeepCleanPalette.ink)
            Spacer()
            Button("Undo") { model.undoLastAction() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .buttonStyle(.plain)
                .accessibilityHint("Cancels the last action")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(accent.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(accent.opacity(0.20), lineWidth: 1)
                }
        }
    }

    // MARK: - Keyboard Card (#1 glassmorphism, #2 shimmer, #7 confetti, #16 VoiceOver)

    private var keyboardCard: some View {
        let active = model.isKeyboardLocked
        let dimmed = model.isTimedSessionActive
        let lastUsed = model.settings.lastUsedCleanMode == .keyboard && !active && !dimmed

        return VStack(spacing: 0) {
            // ⌘K chip
            HStack {
                Spacer()
                ShortcutChip(label: "⌘K")
                    .help("Press ⌘K to toggle keyboard disable")
            }
            .padding(.top, 12)
            .padding(.trailing, 12)

            VStack(spacing: 10) {
                // Icon circle with glow (#7)
                ZStack {
                    if active {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: 58, height: 58)
                            .shadow(color: accent.opacity(0.45), radius: 8)
                    }
                    Circle()
                        .fill(active ? accent.opacity(0.15) : KeepCleanPalette.surface)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle().strokeBorder(
                                active ? accent.opacity(0.45) : KeepCleanPalette.border,
                                lineWidth: 1
                            )
                        }
                    Image(systemName: active ? "keyboard.fill" : "keyboard")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(active ? accent : KeepCleanPalette.ink)
                }

                Text("Keyboard Only")
                    .font(KeepCleanType.title)
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(active ? "Keyboard disabled" : "Trackpad stays active")
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 12)

            Button {
                Task {
                    await model.toggleKeyboardLock()
                    model.settings.lastUsedCleanMode = .keyboard
                    triggerHaptic()
                }
            } label: {
                Text(active ? "Re-enable" : "Disable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(active ? KeepCleanPalette.success : accent)
                    }
            }
            .buttonStyle(KeepCleanPressButtonStyle())
            .disabled(!model.canToggleKeyboard)
            .opacity(model.canToggleKeyboard ? 1 : 0.4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .accessibilityIdentifier("clean.disableKeyboard")
        }
        .frame(maxWidth: .infinity)
        // #1 glassmorphism
        .glassCard(
            border: active
                ? accent.opacity(0.45) : lastUsed ? accent.opacity(0.20) : KeepCleanPalette.border,
            borderWidth: active || lastUsed ? 1.5 : 1
        )
        // #2 shimmer
        .shimmer(when: keyboardShimmer)
        .scaleEffect(active ? 1.02 : (dimmed ? 0.97 : 1.0))
        .opacity(dimmed ? 0.5 : 1.0)
        .shadow(
            color: active ? accent.opacity(0.18) : .black.opacity(0.05),
            radius: active ? 10 : 4, y: 2
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: active)
        .animation(.easeInOut(duration: 0.25), value: dimmed)
        // #16 VoiceOver
        .accessibilityElement(children: .contain)
        .accessibilityLabel(active ? "Keyboard disabled" : "Keyboard Only mode")
        .accessibilityHint(
            active
                ? "Double-tap to re-enable keyboard."
                : "Double-tap Disable button to block the keyboard."
        )
        .accessibilityValue(active ? "Active" : "Inactive")
    }

    // MARK: - Timed Clean Card (#1 glassmorphism, #2 shimmer, #16 VoiceOver)

    private var timedCleanCard: some View {
        let active = model.isTimedSessionActive
        let dimmed = model.isKeyboardLocked
        let lastUsed = model.settings.lastUsedCleanMode == .timed && !active && !dimmed

        return VStack(spacing: 0) {
            HStack {
                Spacer()
                ShortcutChip(label: "⌘F")
                    .help("Press ⌘F to start Full Clean")
            }
            .padding(.top, 12)
            .padding(.trailing, 12)

            VStack(spacing: 10) {
                ZStack {
                    if active {
                        Circle()
                            .fill(KeepCleanPalette.orange.opacity(0.18))
                            .frame(width: 58, height: 58)
                            .shadow(color: KeepCleanPalette.orange.opacity(0.45), radius: 8)
                    }
                    Circle()
                        .fill(
                            active
                                ? KeepCleanPalette.orange.opacity(0.15) : KeepCleanPalette.surface
                        )
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle().strokeBorder(
                                active
                                    ? KeepCleanPalette.orange.opacity(0.45)
                                    : KeepCleanPalette.border,
                                lineWidth: 1
                            )
                        }
                    Image(systemName: active ? "timer.circle.fill" : "timer")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(active ? KeepCleanPalette.orange : KeepCleanPalette.ink)
                }

                Text("Full Clean")
                    .font(KeepCleanType.title)
                    .foregroundStyle(KeepCleanPalette.ink)

                Text(active ? "Locked" : "Both for \(model.settings.fullCleanDurationSeconds)s")
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 12)

            Button {
                Task {
                    if active {
                        await model.cancelTimedSession()
                    } else {
                        await model.startTimedFullClean()
                    }
                    if !active { model.settings.lastUsedCleanMode = .timed }
                    triggerHaptic()
                }
            } label: {
                Text(active ? "Re-enable" : "Disable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(active ? KeepCleanPalette.success : KeepCleanPalette.orange)
                    }
            }
            .buttonStyle(KeepCleanPressButtonStyle())
            .disabled(!model.canStartTimedClean && !active)
            .opacity(model.canStartTimedClean || active ? 1 : 0.4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .accessibilityIdentifier("clean.disableKeyboardAndTrackpad")
        }
        .frame(maxWidth: .infinity)
        // #1 glassmorphism
        .glassCard(
            border: active
                ? KeepCleanPalette.orange.opacity(0.45)
                : lastUsed ? KeepCleanPalette.orange.opacity(0.20) : KeepCleanPalette.border,
            borderWidth: active || lastUsed ? 1.5 : 1
        )
        // #2 shimmer
        .shimmer(when: timedShimmer)
        .scaleEffect(active ? 1.02 : (dimmed ? 0.97 : 1.0))
        .opacity(dimmed ? 0.5 : 1.0)
        .shadow(
            color: active ? KeepCleanPalette.orange.opacity(0.18) : .black.opacity(0.05),
            radius: active ? 10 : 4, y: 2
        )
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: active)
        .animation(.easeInOut(duration: 0.25), value: dimmed)
        // #16 VoiceOver
        .accessibilityElement(children: .contain)
        .accessibilityLabel(active ? "Full Clean active" : "Full Clean mode")
        .accessibilityHint(
            active
                ? "Double-tap to re-enable input."
                : "Double-tap Disable button to block keyboard and trackpad."
        )
        .accessibilityValue(active ? "Active" : "Inactive")
    }

    // MARK: - Timer Display (#3 dual rings, #13 red pulse)

    private func timerDisplay(remaining: Int) -> some View {
        let total = model.settings.fullCleanDurationSeconds
        let progress = total > 0 ? Double(remaining) / Double(total) : 0.0
        let urgent = remaining <= 10
        let timeStr = String(format: "%d:%02d", remaining / 60, remaining % 60)

        return HStack(spacing: 14) {
            // #3 Dual concentric rings
            ZStack {
                // Outer track
                Circle()
                    .stroke(KeepCleanPalette.border.opacity(0.25), lineWidth: 6)
                // Outer ring — time depletes (#8 ring depletes)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        urgent ? KeepCleanPalette.danger : KeepCleanPalette.orange,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Inner ring — always full, teal accent (#3)
                Circle()
                    .stroke(accent.opacity(0.15), lineWidth: 3)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time text (#13 red pulse)
                Text(timeStr)
                    .font(KeepCleanType.mono)
                    .foregroundStyle(urgent ? KeepCleanPalette.danger : KeepCleanPalette.ink)
                    .scaleEffect(urgent ? 1.06 : 1.0)
                    .animation(
                        urgent
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                            : .default,
                        value: urgent
                    )
                    .accessibilityLabel("Time remaining: \(timeStr)")
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cleaning in progress")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Text("Keyboard and trackpad are disabled.")
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((urgent ? KeepCleanPalette.danger : KeepCleanPalette.orange).opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            (urgent ? KeepCleanPalette.danger : KeepCleanPalette.orange).opacity(
                                0.22), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cleaning in progress. Time remaining: \(timeStr).")
    }

    // MARK: - Auto-Start Banner (#21 prominent card)

    private func autoStartBanner(countdown: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: "timer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-starting in \(countdown)…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Text("Keyboard will be disabled automatically.")
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }
            Spacer()
            Button("Cancel") { model.cancelAutoStart() }
                .font(.system(size: 13, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(accent)
                .accessibilityIdentifier("clean.cancelAutoStart")
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(accent.opacity(0.22), lineWidth: 1)
                }
        }
    }

    // MARK: - FAQ (#18)

    private var faqDisclosure: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                faqItem(
                    "Keyboard still responding?",
                    answer:
                        "Make sure both Accessibility and Input Monitoring are granted in System Settings > Privacy & Security."
                )
                faqItem(
                    "External keyboard blocked?",
                    answer:
                        "No — KeepClean only blocks the built-in keyboard. External keyboards and mice are always active."
                )
                faqItem(
                    "Trackpad still moves the cursor?",
                    answer:
                        "The Keyboard Only mode leaves the trackpad active. Use Full Clean to block both."
                )
                faqItem(
                    "Session ends when Mac sleeps?",
                    answer:
                        "Yes — KeepClean automatically ends sessions when the Mac goes to sleep so you never wake up to a locked keyboard."
                )
            }
            .padding(.top, 6)
        } label: {
            Label("Troubleshooting", systemImage: "questionmark.circle")
                .font(KeepCleanType.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
        .tint(KeepCleanPalette.mutedInk)
        .padding(.vertical, 4)
    }

    private func faqItem(_ question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(question)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(KeepCleanPalette.ink)
            Text(answer)
                .font(.system(size: 11))
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Status Bar (#9)

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    model.activeSession != nil ? KeepCleanPalette.orange : KeepCleanPalette.success
                )
                .frame(width: 6, height: 6)
                .shadow(
                    color: (model.activeSession != nil
                        ? KeepCleanPalette.orange : KeepCleanPalette.success).opacity(0.6),
                    radius: 3)

            Text(model.statusMessage)
                .font(KeepCleanType.caption)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
        .help(
            model.activeSession != nil
                ? "A session is active — input is being blocked."
                : "KeepClean is idle — keyboard and trackpad are active."
        )
        .accessibilityLabel(model.statusMessage)
    }

    // MARK: - Haptic (#16)

    private func triggerHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
}

// MARK: - Previews (#30)

#Preview("Idle") {
    CleanTabView(model: .preview())
        .padding()
}

#Preview("Timed Active") {
    let m = AppViewModel.preview()
    m.remainingTimedLockSeconds = 47
    return CleanTabView(model: m)
        .padding()
}
