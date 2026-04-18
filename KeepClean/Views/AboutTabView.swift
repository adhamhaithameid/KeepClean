import AppKit
import SwiftUI

struct AboutTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                linksPanel
                creditsPanel
            }
        }
    }

    private var linksPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "About")

            Text("A small offline Mac utility for cleaning the built-in keyboard and trackpad.")
                .font(.body)
                .foregroundStyle(KeepCleanPalette.mutedInk)

            HStack(alignment: .top, spacing: 18) {
                Button {
                    model.open(.profile)
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        ProfileAvatarView()
                        Text("Adham Haitham Eid")
                            .font(.headline)
                            .foregroundStyle(KeepCleanPalette.ink)
                        Text("Open GitHub profile")
                            .font(.subheadline)
                            .foregroundStyle(KeepCleanPalette.mutedInk)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.profile")

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 10) {
                    Button("Donate") {
                        model.open(.donation)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KeepCleanPalette.orange)
                    .accessibilityIdentifier("about.donate")

                    Button("GitHub Repo") {
                        model.open(.repository)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KeepCleanPalette.blue)
                    .accessibilityIdentifier("about.repo")
                }
            }
        }
    }

    private var creditsPanel: some View {
        KeepCleanPanel {
            KeepCleanSectionEyebrow(text: "Credits")
            Text("Made with love, coffee, VS Code, and Figma.")
                .font(.headline)
                .foregroundStyle(KeepCleanPalette.ink)
            Text("Built for practicing Swift as a junior software engineer.")
                .font(.subheadline)
                .foregroundStyle(KeepCleanPalette.mutedInk)
        }
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
                    .fill(KeepCleanPalette.blueSoft)
                    .overlay {
                        Text("AE")
                            .font(.title.bold())
                    }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }
}
