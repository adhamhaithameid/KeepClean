import SwiftUI

/// First-launch setup: guides through granting Accessibility and
/// Input Monitoring (both required for keyboard blocking to work).
///
/// Redesigned as a linear step-by-step wizard:
///  Step 1 → Grant Accessibility
///  Step 2 → Grant Input Monitoring
///  Done    → Continue button unlocked
struct PermissionSetupView: View {
    @ObservedObject var model: PermissionSetupViewModel

    // Tracks which step card is actively expanded for focus
    @State private var focusedStep: SetupStep = .accessibility

    enum SetupStep: Int, CaseIterable {
        case accessibility = 1
        case inputMonitoring = 2
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 28)
                        .padding(.bottom, 20)

                    // Progress breadcrumb
                    progressIndicator
                        .padding(.bottom, 20)

                    // Permission Steps
                    VStack(spacing: 12) {
                        accessibilityStep
                        inputMonitoringStep
                    }
                    .padding(.horizontal, 24)

                    // Continue button
                    continueSection
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 520, height: 520)
        // Polling is started only on user action — no eager background polling.
        .onDisappear { model.stopPolling() }
        // Auto-advance focus to step 2 once step 1 is done.
        .modifier(
            AccessibilityGrantedAdvanceModifier(
                granted: model.accessibilityGranted, focusedStep: $focusedStep))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            KeepCleanBrandMark(size: 60)

            Text("One-Time Setup")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(KeepCleanPalette.ink)

            Text(
                "KeepClean needs two permissions to block your keyboard and trackpad. This takes about 30 seconds."
            )
            .font(.system(size: 12))
            .foregroundStyle(KeepCleanPalette.mutedInk)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        let step1Done = model.accessibilityGranted
        let step2Done = model.inputMonitoringGranted || model.userConfirmedInputMonitoring
        let completedCount = [step1Done, step2Done].filter { $0 }.count

        return HStack(spacing: 8) {
            stepDot(number: 1, done: step1Done, active: focusedStep == .accessibility)
            progressLine(filled: step1Done)
            stepDot(number: 2, done: step2Done, active: focusedStep == .inputMonitoring)

            Spacer().frame(maxWidth: 0)

            Text("\(completedCount) of 2 complete")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
        .padding(.horizontal, 24)
    }

    private func stepDot(number: Int, done: Bool, active: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    done
                        ? KeepCleanPalette.success
                        : (active ? KeepCleanPalette.blue : KeepCleanPalette.border)
                )
                .frame(width: 24, height: 24)

            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(active ? .white : KeepCleanPalette.mutedInk)
            }
        }
        .animation(.spring(response: 0.3), value: done)
    }

    private func progressLine(filled: Bool) -> some View {
        Rectangle()
            .fill(filled ? KeepCleanPalette.success : KeepCleanPalette.border)
            .frame(width: 40, height: 2)
            .cornerRadius(1)
            .animation(.easeInOut(duration: 0.4), value: filled)
    }

    // MARK: - Step 1: Accessibility

    private var accessibilityStep: some View {
        permissionStepCard(
            step: .accessibility,
            granted: model.accessibilityGranted,
            icon: "keyboard",
            title: "Accessibility",
            whyNeeded:
                "Lets KeepClean intercept keystrokes so they don't activate apps while you clean your keyboard.",
            grantButtonTitle: "Grant Accessibility",
            grantAction: {
                model.requestAccessibility()
                withAnimation { focusedStep = .accessibility }
            }
        ) {
            EmptyView()
        }
    }

    // MARK: - Step 2: Input Monitoring

    private var inputMonitoringStep: some View {
        let effectivelyGranted = model.inputMonitoringGranted || model.userConfirmedInputMonitoring

        return permissionStepCard(
            step: .inputMonitoring,
            granted: effectivelyGranted,
            icon: "hand.point.up",
            title: "Input Monitoring",
            whyNeeded:
                "Required for the keyboard block to actually drop events. Without it, macOS silently ignores the event tap.",
            grantButtonTitle: "Grant Input Monitoring",
            grantAction: {
                model.requestInputMonitoring()
                withAnimation { focusedStep = .inputMonitoring }
            }
        ) {
            if !effectivelyGranted {
                VStack(alignment: .leading, spacing: 8) {
                    // Secondary action: reveal in Finder for drag-to-add workflow
                    Button("Show App in Finder") {
                        model.revealAppInFinder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("setup.revealInFinder")

                    // Expandable manual steps
                    howToAddInputMonitoring

                    // Manual override — shown after overrideTimerDelay
                    if model.showManualOverride {
                        manualOverrideSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    // MARK: - Permission Step Card

    private func permissionStepCard<Extra: View>(
        step: SetupStep,
        granted: Bool,
        icon: String,
        title: String,
        whyNeeded: String,
        grantButtonTitle: String,
        grantAction: @escaping () -> Void,
        @ViewBuilder extra: () -> Extra
    ) -> some View {
        let isFocused = focusedStep == step
        let isLocked = step == .inputMonitoring && !model.accessibilityGranted

        return VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(
                            granted
                                ? KeepCleanPalette.success.opacity(0.15)
                                : (isLocked
                                    ? Color.gray.opacity(0.08) : KeepCleanPalette.blue.opacity(0.1))
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: granted ? "checkmark" : icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            granted
                                ? KeepCleanPalette.success
                                : (isLocked ? KeepCleanPalette.mutedInk : KeepCleanPalette.blue))
                }
                .animation(.spring(response: 0.3), value: granted)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(
                                isLocked ? KeepCleanPalette.mutedInk : KeepCleanPalette.ink)

                        statusBadge(granted: granted, locked: isLocked)
                    }

                    // "Why needed" explainer
                    if isFocused || !granted {
                        Text(whyNeeded)
                            .font(.system(size: 11))
                            .foregroundStyle(KeepCleanPalette.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !granted && !isLocked else { return }
                withAnimation(.spring(response: 0.35)) {
                    focusedStep = step
                }
            }

            // Expanded content (grant button + extras)
            if !granted && !isLocked {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 8) {
                        // Primary CTA
                        Button(action: grantAction) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(grantButtonTitle)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(KeepCleanPalette.blue)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            step == .accessibility
                                ? "setup.grantAccessibility" : "setup.grantInputMonitoring")

                        extra()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if isLocked && !granted {
                HStack(spacing: 6) {
                    Image(systemName: "lock")
                        .font(.system(size: 10))
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                    Text("Complete Step 1 first")
                        .font(.system(size: 11))
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            granted
                                ? KeepCleanPalette.success.opacity(0.5)
                                : (isFocused && !isLocked
                                    ? KeepCleanPalette.blue.opacity(0.4) : KeepCleanPalette.border),
                            lineWidth: granted ? 1.5 : 1
                        )
                }
                // Green glow pulse when just granted
                .shadow(
                    color: granted ? KeepCleanPalette.success.opacity(0.2) : .clear, radius: 8, y: 2
                )
        }
        .animation(.easeInOut(duration: 0.3), value: granted)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }

    private func statusBadge(granted: Bool, locked: Bool) -> some View {
        Group {
            if granted {
                Text("GRANTED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(KeepCleanPalette.success)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(KeepCleanPalette.success.opacity(0.12), in: Capsule())
            } else if locked {
                Text("STEP 1 FIRST")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(KeepCleanPalette.mutedInk.opacity(0.10), in: Capsule())
            } else {
                Text("REQUIRED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(KeepCleanPalette.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(KeepCleanPalette.blue.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - Manual Override

    private var manualOverrideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)

                Text("Already granted but not detected?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(KeepCleanPalette.ink)
            }

            Text(
                "macOS sometimes doesn't report permission changes to running apps (especially ad-hoc signed builds). If you've already toggled Input Monitoring ON for KeepClean, click below."
            )
            .font(.system(size: 11))
            .foregroundStyle(KeepCleanPalette.mutedInk)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("I've Already Granted It") {
                    model.confirmInputMonitoringGranted()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
                .accessibilityIdentifier("setup.confirmInputMonitoring")

                Button("Refresh Detection") {
                    model.manualRefresh()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("setup.refreshDetection")
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.orange.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - How-to (Input Monitoring manual steps)

    private var howToAddInputMonitoring: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                manualStep(
                    "1", icon: "gearshape",
                    "Open System Settings → Privacy & Security → Input Monitoring")
                manualStep(
                    "2", icon: "plus.circle", "Click the \"+\" button at the bottom of the list")
                manualStep(
                    "3", icon: "arrow.down.app",
                    "Use \"Show App in Finder\" above, then drag KeepClean.app into the dialog")
                manualStep("4", icon: "checkmark.circle", "Make sure the toggle switch is ON")
            }
            .padding(.top, 6)
        } label: {
            Text("How to add manually →")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(KeepCleanPalette.blue)
        }
        .font(.system(size: 11))
    }

    private func manualStep(_ number: String, icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(KeepCleanPalette.blue)
                .frame(width: 18, alignment: .center)

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Continue Section

    private var continueSection: some View {
        VStack(spacing: 6) {
            Button(action: { model.completeSetup() }) {
                HStack(spacing: 8) {
                    if model.canProceed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(
                        model.canProceed
                            ? "Continue to KeepClean" : "Grant both permissions above to continue"
                    )
                    .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(model.canProceed ? KeepCleanPalette.success : Color.gray.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            .disabled(!model.canProceed)
            .padding(.horizontal, 24)
            .accessibilityIdentifier("setup.continue")
            .animation(.spring(response: 0.35), value: model.canProceed)

            if model.canProceed {
                Text("Both permissions are active. You're all set! ✓")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.success)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.canProceed)
    }
}

// MARK: - Cross-version auto-advance modifier

/// Advances the focused step to .inputMonitoring when Accessibility is granted.
/// Uses the deprecated single-param onChange on macOS 13 and the
/// non-deprecated two-param form on macOS 14+.
private struct AccessibilityGrantedAdvanceModifier: ViewModifier {
    let granted: Bool
    @Binding var focusedStep: PermissionSetupView.SetupStep

    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content.onChange(of: granted) { _, isGranted in
                advance(if: isGranted)
            }
        } else {
            content.onChange(of: granted) { isGranted in
                advance(if: isGranted)
            }
        }
    }

    private func advance(if isGranted: Bool) {
        if isGranted && focusedStep == .accessibility {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                focusedStep = .inputMonitoring
            }
        }
    }
}
