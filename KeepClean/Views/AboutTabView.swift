import AppKit
import SwiftUI

struct AboutTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroPanel
                linksPanel
                footerPanel
            }
        }
    }

    private var heroPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.amber) {
            HStack(alignment: .center, spacing: 18) {
                KeepCleanBrandMark(size: 82)

                VStack(alignment: .leading, spacing: 6) {
                    KeepCleanSectionEyebrow(text: "About KeepClean")
                    Text("A tiny macOS utility with a cleaner personality.")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(KeepCleanPalette.ink)
                    Text("Simple on purpose, local by default, and built as a practice project in Swift.")
                        .font(.headline)
                        .foregroundStyle(KeepCleanPalette.ink.opacity(0.70))
                }

                Spacer()
            }
        }
    }

    private var linksPanel: some View {
        KeepCleanPanel(accent: KeepCleanPalette.sky) {
            KeepCleanSectionEyebrow(text: "Links")

            HStack(alignment: .top, spacing: 18) {
                Button {
                    model.open(.profile)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        ProfileAvatarView()
                        Text("Adham Haitham Eid")
                            .font(.headline)
                            .foregroundStyle(KeepCleanPalette.ink)
                        Text("Tap the profile image to open the GitHub profile.")
                            .font(.subheadline)
                            .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.profile")

                VStack(spacing: 12) {
                    Button {
                        model.open(.donation)
                    } label: {
                        actionTile(
                            title: "Donate",
                            subtitle: "Support the project with a coffee.",
                            tint: KeepCleanPalette.warning
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("about.donate")

                    Button {
                        model.open(.repository)
                    } label: {
                        actionTile(
                            title: "GitHub Repo",
                            subtitle: "Open the public source repository.",
                            tint: KeepCleanPalette.sky
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("about.repo")
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private var footerPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Credits")
            Text("Made with love, coffee, VS Code, and Figma.")
                .font(.title3.weight(.bold))
                .foregroundStyle(KeepCleanPalette.ink)
            Text("Built for practicing Swift as a junior software engineer.")
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink.opacity(0.72))
        }
    }

    private func actionTile(title: String, subtitle: String, tint: Color) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(tint)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(KeepCleanPalette.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(KeepCleanPalette.ink.opacity(0.68))
            }

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.68))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.88), lineWidth: 1)
                }
        )
    }
}

private struct ProfileAvatarView: View {
    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "profile", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(KeepCleanPalette.sky.opacity(0.15))
                    .overlay {
                        Text("AE")
                            .font(.title.bold())
                    }
            }
        }
        .frame(width: 122, height: 122)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.90), lineWidth: 4))
        .shadow(color: KeepCleanPalette.ink.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}
