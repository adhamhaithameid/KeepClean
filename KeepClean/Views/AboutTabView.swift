import SwiftUI

struct AboutTabView: View {
    @Bindable var model: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("About")
                .font(.system(size: 30, weight: .bold))

            Button {
                model.open(.profile)
            } label: {
                ProfileAvatarView()
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("about.profile")

            HStack(spacing: 14) {
                Button("Donate") {
                    model.open(.donation)
                }
                .accessibilityIdentifier("about.donate")

                Button("GitHub Repo") {
                    model.open(.repository)
                }
                .accessibilityIdentifier("about.repo")
            }
            .buttonStyle(.borderedProminent)

            VStack(alignment: .leading, spacing: 6) {
                Text("Made with love, coffee, VS Code, and Figma.")
                Text("Built for practicing Swift as a junior software engineer.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
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
                    .fill(Color.accentColor.opacity(0.15))
                    .overlay {
                        Text("AE")
                            .font(.title.bold())
                    }
            }
        }
        .frame(width: 108, height: 108)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.accentColor.opacity(0.25), lineWidth: 3))
    }
}
