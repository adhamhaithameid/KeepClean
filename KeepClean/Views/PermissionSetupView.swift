import SwiftUI

/// First-launch setup: guides through granting Accessibility and
/// Input Monitoring (both required for keyboard blocking to work).
struct PermissionSetupView: View {
    @ObservedObject var model: PermissionSetupViewModel

    var body: some View {
        ZStack {
            KeepCleanAmbientBackground()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 32)
                        .padding(.bottom, 24)

                    VStack(spacing: 14) {
                        // Step 1: Accessibility (REQUIRED)
                        accessibilityRow

                        // Step 2: Input Monitoring (REQUIRED)
                        inputMonitoringRow
                    }
                    .padding(.horizontal, 28)

                    continueButton
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 520, minHeight: 520)
        .onAppear { model.startPolling() }
        .onDisappear { model.stopPolling() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            KeepCleanBrandMark(size: 64)

            Text("One-Time Setup")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(KeepCleanPalette.ink)

            Text("Grant both permissions to start using KeepClean.")
                .font(.system(size: 13))
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Accessibility Row (Required)

    private var accessibilityRow: some View {
        permissionCard(
            granted: model.accessibilityGranted,
            icon: "keyboard",
            title: "Accessibility",
            tag: "Required",
            tagColor: KeepCleanPalette.blue
        ) {
            if !model.accessibilityGranted {
                Text("Needed to intercept keyboard events.")
                    .font(.system(size: 12))
                    .foregroundStyle(KeepCleanPalette.mutedInk)

                Button("Grant Accessibility") {
                    model.requestAccessibility()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .accessibilityIdentifier("setup.grantAccessibility")
            }
        }
    }

    // MARK: - Input Monitoring Row (Required)

    private var inputMonitoringRow: some View {
        let effectivelyGranted = model.inputMonitoringGranted || model.userConfirmedInputMonitoring

        return permissionCard(
            granted: effectivelyGranted,
            icon: "hand.point.up",
            title: "Input Monitoring",
            tag: "Required",
            tagColor: KeepCleanPalette.blue
        ) {
            if !effectivelyGranted {
                Text("Required for keyboard blocking to actually block events. Without it, the event tap is silently ignored by macOS.")
                    .font(.system(size: 12))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button("Open Input Monitoring") {
                        model.requestInputMonitoring()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("setup.grantInputMonitoring")

                    Button("Show App in Finder") {
                        model.revealAppInFinder()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("setup.revealInFinder")
                }

                howToAddInputMonitoring

                // Manual override — shown after a delay when detection fails
                if model.showManualOverride {
                    manualOverrideSection
                }
            }
        }
    }

    // MARK: - Manual Override

    private var manualOverrideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 4)

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)

                Text("Already granted but not detected?")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(KeepCleanPalette.ink)
            }

            Text("macOS sometimes doesn't report permission changes to running apps (especially ad-hoc signed builds). If you've already toggled Input Monitoring ON for KeepClean, click below.")
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - How-to

    private var howToAddInputMonitoring: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                step("1", "Open System Settings \u{2192} Privacy & Security \u{2192} Input Monitoring")
                step("2", "Click the \"+\" button at the bottom")
                step("3", "Use \"Show App in Finder\" above, then drag KeepClean.app into the dialog")
                step("4", "Make sure the switch is ON")
            }
            .padding(.top, 4)
        } label: {
            Text("How to add manually")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(KeepCleanPalette.blue)
        }
        .font(.system(size: 11))
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(number + ".")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(KeepCleanPalette.blue)
                .frame(width: 16, alignment: .trailing)

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Permission Card

    private func permissionCard<Content: View>(
        granted: Bool,
        icon: String,
        title: String,
        tag: String,
        tagColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(granted ? KeepCleanPalette.success.opacity(0.15) : KeepCleanPalette.blue.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: granted ? "checkmark" : icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(granted ? KeepCleanPalette.success : KeepCleanPalette.blue)
                }
                .animation(.spring(response: 0.3), value: granted)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.ink)

                        if granted {
                            Text("GRANTED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(KeepCleanPalette.success)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(KeepCleanPalette.success.opacity(0.12), in: Capsule())
                        } else {
                            Text(tag)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tagColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(tagColor.opacity(0.12), in: Capsule())
                        }
                    }
                }

                Spacer()
            }

            content()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            granted ? KeepCleanPalette.success.opacity(0.4) : KeepCleanPalette.border,
                            lineWidth: 1
                        )
                }
        }
        .animation(.easeInOut(duration: 0.3), value: granted)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack(spacing: 8) {
            Button(action: { model.completeSetup() }) {
                Text(model.canProceed ? "Continue to KeepClean" : "Grant both permissions to continue")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(model.canProceed ? KeepCleanPalette.success : Color.gray.opacity(0.35))
                    }
            }
            .buttonStyle(.plain)
            .disabled(!model.canProceed)
            .padding(.horizontal, 28)
            .accessibilityIdentifier("setup.continue")
            .animation(.easeInOut(duration: 0.3), value: model.canProceed)
        }
    }
}
