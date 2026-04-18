import SwiftUI

struct RootTabsView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(AppTab.allCases) { tab in
                    Button(tab.title) {
                        model.selectedTab = tab
                    }
                    .buttonStyle(KeepCleanTabButtonStyle(isSelected: model.selectedTab == tab))
                    .accessibilityIdentifier("tab.\(tab.rawValue)")
                }
            }
            .padding(20)

            Divider()

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
            .padding(24)
        }
        .frame(minWidth: 760, minHeight: 560)
        .task {
            model.handleInitialAppearance()
        }
    }
}

private struct KeepCleanTabButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(configuration.isPressed ? 0.18 : 0.1))
            )
    }
}
