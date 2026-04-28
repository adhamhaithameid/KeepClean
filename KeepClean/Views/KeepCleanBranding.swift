import AppKit
import SwiftUI

// MARK: - Color Palette

enum KeepCleanPalette {
    // Primary brand color — teal
    static let teal = Color(hue: 0.484, saturation: 0.56, brightness: 0.63)
    static let tealSoft = teal.opacity(0.12)
    static let tealGlow = teal.opacity(0.28)

    // Legacy aliases used across the codebase
    static var blue: Color { teal }
    static var blueSoft: Color { tealSoft }

    // State colors
    static let orange = Color(red: 0.92, green: 0.47, blue: 0.16)
    static let success = Color(red: 0.17, green: 0.60, blue: 0.38)
    static let danger = Color(red: 0.85, green: 0.25, blue: 0.22)

    // Surfaces — adaptive via NSColor so they respect light / dark mode automatically
    static let ink = Color.primary
    static let mutedInk = Color.secondary
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let surfaceWarm = Color(nsColor: .controlBackgroundColor)
    static let surfaceElevated = Color(nsColor: .underPageBackgroundColor)
    static let border = Color(nsColor: .separatorColor).opacity(0.65)
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let subtleFill = Color(nsColor: .textBackgroundColor)
}

// MARK: - Type Scale

enum KeepCleanType {
    static let display = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.body.weight(.regular)
    static let caption = Font.caption.weight(.medium)
    static let mono = Font.system(size: 18, weight: .bold, design: .monospaced)
}

// MARK: - App Display State

enum AppDisplayState: Equatable {
    case idle
    case countdown(Int)
    case keyboardLocked
    case timedActive(secondsRemaining: Int)
}

extension AppViewModel {
    var displayState: AppDisplayState {
        if let t = remainingTimedLockSeconds { return .timedActive(secondsRemaining: t) }
        if let c = autoStartCountdownSecondsRemaining { return .countdown(c) }
        if isKeyboardLocked { return .keyboardLocked }
        return .idle
    }
}

// MARK: - Brand Mark

struct KeepCleanBrandMark: View {
    var size: CGFloat = 64
    var hoverRotate: Bool = false
    /// When true the mark slowly spins (1 full rotation per 8 s) to signal an active session.
    var spinning: Bool = false

    @State private var isHovered = false
    @State private var spinDegrees = 0.0

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: "brand-mark", withExtension: "png"),
                let image = NSImage(contentsOf: url)
            {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(KeepCleanPalette.surfaceWarm)
                    .overlay {
                        Text("K")
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(KeepCleanPalette.teal)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                    }
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(
            spinning
                ? .degrees(spinDegrees) : (hoverRotate && isHovered ? .degrees(3) : .degrees(0))
        )
        .animation(
            hoverRotate && !spinning
                ? .spring(response: 0.4, dampingFraction: 0.5)
                : nil,
            value: isHovered
        )
        .onHover { isHovered = $0 }
        .onAppear {
            guard spinning else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                spinDegrees = 360
            }
        }
        .onChange(of: spinning) { nowSpinning in
            if nowSpinning {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    spinDegrees = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.4)) { spinDegrees = 0 }
            }
        }
        .accessibilityHidden(true)
    }
}
