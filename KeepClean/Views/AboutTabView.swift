import AppKit
import SwiftUI

struct AboutTabView: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // App icon
                KeepCleanBrandMark(size: 80)

                // App name and version
                VStack(spacing: 4) {
                    Text("KeepClean")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(KeepCleanPalette.ink)

                    Text("Version 1.0.0")
                        .font(.system(size: 13))
                        .foregroundStyle(KeepCleanPalette.mutedInk)
                }

                // Description
                Text("Temporarily disable your MacBook's built-in keyboard and trackpad for cleaning.")
                    .font(.system(size: 13))
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                // Links
                HStack(spacing: 12) {
                    linkButton(
                        title: "GitHub",
                        icon: "chevron.left.forwardslash.chevron.right",
                        identifier: "about.repo"
                    ) {
                        model.open(.repository)
                    }

                    linkButton(
                        title: "Donate",
                        icon: "cup.and.saucer.fill",
                        identifier: "about.donate"
                    ) {
                        model.open(.donation)
                    }
                }
            }

            Spacer()

            // Footer
            VStack(spacing: 4) {
                Button {
                    model.open(.profile)
                } label: {
                    Text("Made by Adham Haitham")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(KeepCleanPalette.blue)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.profile")

                Text("Built with Swift & SwiftUI")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk.opacity(0.6))
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func linkButton(
        title: String,
        icon: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(KeepCleanPalette.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(KeepCleanPalette.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
