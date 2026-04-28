import SwiftUI

struct RootTabsView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Liquid-glass window background — blends with the desktop behind the window
            VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()

            // ── Content VStack — fills the window, scrolling handled per-tab ──
            VStack(spacing: 16) {
                tabBar
                    .padding(.top, 16)

                // Tab content — expands to fill remaining window height
                ZStack {
                    switch model.selectedTab {
                    case .clean:
                        CleanTabView(model: model)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                            .id(AppTab.clean)

                    case .settings:
                        SettingsTabView(
                            settings: model.settings,
                            model: model,
                            openPrivacyAndSecurity: model.openPrivacyAndSecurity,
                            hasAccessibility: model.hasAccessibility,
                            hasInputMonitoring: model.hasInputMonitoring
                        )
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                        .id(AppTab.settings)

                    case .about:
                        AboutTabView(model: model)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                            .id(AppTab.about)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.32, dampingFraction: 0.88), value: model.selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Toast overlay
            if let toast = model.toastMessage {
                toastView(message: toast, isError: model.toastIsError)
                    .padding(20)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8), value: model.toastMessage)
            }
        }
        .task { model.handleInitialAppearance() }
        .background {
            Button("") { model.selectedTab = .settings }
                .keyboardShortcut(",", modifiers: .command)
                .opacity(0).allowsHitTesting(false)
        }
        .background {
            Button("") {
                model.selectedTab = .clean
                Task { await model.startTimedFullClean() }
            }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0).allowsHitTesting(false)
        }
        .tint(KeepCleanPalette.teal)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        // #25 ⌘, opens Settings
        .background(
            Button("") { model.selectedTab = .settings }
                .keyboardShortcut(",", modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
        )
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = model.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                model.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))

                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.white : KeepCleanPalette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(KeepCleanPalette.teal)
                        .shadow(color: KeepCleanPalette.teal.opacity(0.30), radius: 4, y: 2)
                }
            }
        }
        .buttonStyle(KeepCleanPressButtonStyle())  // #11 spring press on tabs too
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }

    // MARK: - Toast (#14 auto-dismiss with depleting bar)

    private func toastView(message: String, isError: Bool) -> some View {
        ToastView(message: message, isError: isError, onDismiss: { model.dismissToast() })
    }
}

// MARK: - Toast View with auto-dismiss (#14)

private struct ToastView: View {
    let message: String
    let isError: Bool
    let onDismiss: () -> Void

    @State private var progress: CGFloat = 1.0
    private let duration: Double = 4.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(
                    systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isError ? KeepCleanPalette.danger : KeepCleanPalette.success)

                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(KeepCleanPalette.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    withAnimation { onDismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Depleting progress bar (#14)
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        (isError ? KeepCleanPalette.danger : KeepCleanPalette.success).opacity(0.6)
                    )
                    .frame(width: geo.size.width * progress, height: 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 2)
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isError
                                ? KeepCleanPalette.danger.opacity(0.3)
                                : KeepCleanPalette.success.opacity(0.3),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .frame(maxWidth: 320)
        .onAppear {
            // Animate the bar to 0 over `duration` seconds, then auto-dismiss
            withAnimation(.linear(duration: duration)) {
                progress = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation { onDismiss() }
            }
        }
    }
}

// MARK: - Preview (#30)

#Preview("Main UI") {
    RootTabsView(model: .preview())
}
