import SwiftUI

struct RootTabsView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main content
            ZStack(alignment: .top) {
                KeepCleanAmbientBackground()

                VStack(spacing: 16) {
                    tabBar
                        .padding(.top, 16)

                    Group {
                        switch model.selectedTab {
                        case .clean:
                            CleanTabView(model: model)
                        case .settings:
                            SettingsTabView(
                                settings: model.settings,
                                openPrivacyAndSecurity: model.openPrivacyAndSecurity
                            )
                        case .about:
                            AboutTabView(model: model)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }

            // Toast notification overlay (bottom-right)
            if let toast = model.toastMessage {
                toastView(message: toast, isError: model.toastIsError)
                    .padding(20)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: model.toastMessage)
            }
        }
        .frame(minWidth: 500, minHeight: 380)
        .task {
            model.handleInitialAppearance()
        }
    }

    // MARK: - Tab Bar (Centered)

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func tabButton(for tab: AppTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                model.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(tab.title)
                    .font(.system(size: 13, weight: model.selectedTab == tab ? .semibold : .medium))
            }
            .foregroundStyle(model.selectedTab == tab ? Color.white : KeepCleanPalette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if model.selectedTab == tab {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(KeepCleanPalette.blue)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }

    // MARK: - Toast

    private func toastView(message: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isError ? .red : KeepCleanPalette.success)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KeepCleanPalette.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                model.dismissToast()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(KeepCleanPalette.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isError ? Color.red.opacity(0.3) : KeepCleanPalette.success.opacity(0.3),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .frame(maxWidth: 320)
    }
}
