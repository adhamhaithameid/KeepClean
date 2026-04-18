import SwiftUI

struct RootTabsView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ZStack {
            KeepCleanAmbientBackground()

            VStack(spacing: 16) {
                header
                tabBar

                Group {
                    switch model.selectedTab {
                    case .clean:
                        CleanTabView(model: model)
                    case .settings:
                        SettingsTabView(settings: model.settings)
                    case .about:
                        AboutTabView(model: model)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(20)
        }
        .frame(minWidth: 780, minHeight: 580)
        .task {
            model.handleInitialAppearance()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            KeepCleanBrandMark(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("KeepClean")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(KeepCleanPalette.ink)
                Text("Built-in keyboard and trackpad cleaning.")
                    .font(.subheadline)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
            }

            Spacer()

            KeepCleanStatusPill(text: currentPillText, tint: currentPillTint)
        }
        .padding(.horizontal, 4)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases) { tab in
                Button(tab.title) {
                    model.selectedTab = tab
                }
                .buttonStyle(KeepCleanTabChipStyle(isSelected: model.selectedTab == tab))
                .accessibilityIdentifier("tab.\(tab.rawValue)")
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                }
        )
    }

    private var currentPillText: String {
        switch model.selectedTab {
        case .clean:
            model.activeSession == nil ? "Ready" : "Active"
        case .settings:
            "Preferences"
        case .about:
            "Local app"
        }
    }

    private var currentPillTint: Color {
        switch model.selectedTab {
        case .clean:
            model.activeSession == nil ? KeepCleanPalette.success : KeepCleanPalette.orange
        case .settings:
            KeepCleanPalette.blue
        case .about:
            KeepCleanPalette.mutedInk
        }
    }
}
