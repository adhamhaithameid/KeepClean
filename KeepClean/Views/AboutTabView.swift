import AppKit
import SwiftUI

struct AboutTabView: View {
    @ObservedObject var model: AppViewModel
    private let accent = KeepCleanPalette.teal
    @State private var githubHovered = false
    @State private var donateHovered = false

    // #4 — mark spins while any session is active
    private var sessionActive: Bool {
        model.activeSession != nil || model.isKeyboardLocked
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            VStack(spacing: 20) {
                // Brand mark — spins while any session is active (#4)
                KeepCleanBrandMark(size: 80, hoverRotate: true, spinning: sessionActive)
                    .shadow(color: accent.opacity(0.25), radius: 14, y: 4)

                VStack(spacing: 4) {
                    Text("KeepClean")
                        .font(KeepCleanType.display)
                        .foregroundStyle(KeepCleanPalette.ink)

                    Text(
                        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
                    )
                    .font(KeepCleanType.caption)
                    .foregroundStyle(KeepCleanPalette.mutedInk)
                }

                Text(
                    "Temporarily disable your MacBook's built-in keyboard and trackpad for cleaning."
                )
                .font(KeepCleanType.body)
                .foregroundStyle(KeepCleanPalette.mutedInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

                // Pill link chips
                HStack(spacing: 10) {
                    linkChip(
                        title: "GitHub",
                        icon: "chevron.left.forwardslash.chevron.right",
                        identifier: "about.repo",
                        hovered: $githubHovered,
                        tint: accent
                    ) { model.open(.repository) }

                    linkChip(
                        title: "Donate",
                        icon: "cup.and.saucer.fill",
                        identifier: "about.donate",
                        hovered: $donateHovered,
                        tint: KeepCleanPalette.orange
                    ) { model.open(.donation) }
                }

                // Live session indicator
                if sessionActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(KeepCleanPalette.orange)
                            .frame(width: 7, height: 7)
                            .shadow(color: KeepCleanPalette.orange.opacity(0.7), radius: 4)
                        Text("Session active")
                            .font(KeepCleanType.caption)
                            .foregroundStyle(KeepCleanPalette.orange)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }

            Spacer(minLength: 20)

            VStack(spacing: 4) {
                Button {
                    model.open(.profile)
                } label: {
                    Text("Made by Adham Haitham")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("about.profile")

                Text("Built with Swift & SwiftUI")
                    .font(.system(size: 11))
                    .foregroundStyle(KeepCleanPalette.mutedInk.opacity(0.6))
                    .accessibilityIdentifier("about.builtWith")
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: sessionActive)
    }

    private func linkChip(
        title: String,
        icon: String,
        identifier: String,
        hovered: Binding<Bool>,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(hovered.wrappedValue ? .white : KeepCleanPalette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background {
                Capsule(style: .continuous)
                    .fill(hovered.wrappedValue ? tint : KeepCleanPalette.surface)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(
                                hovered.wrappedValue ? tint.opacity(0) : KeepCleanPalette.border,
                                lineWidth: 1)
                    }
                    .shadow(
                        color: hovered.wrappedValue ? tint.opacity(0.3) : .clear, radius: 8, y: 3)
            }
        }
        .buttonStyle(KeepCleanPressButtonStyle())
        .onHover { hovered.wrappedValue = $0 }
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: hovered.wrappedValue)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    AboutTabView(model: .preview())
        .frame(width: 520)
}
