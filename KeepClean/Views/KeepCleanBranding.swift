import SwiftUI

enum KeepCleanPalette {
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.22)
    static let mutedInk = Color(red: 0.40, green: 0.43, blue: 0.49)
    static let blue = Color(red: 0.18, green: 0.46, blue: 0.92)
    static let blueSoft = Color(red: 0.88, green: 0.93, blue: 1.00)
    static let orange = Color(red: 0.95, green: 0.52, blue: 0.19)
    static let success = Color(red: 0.21, green: 0.60, blue: 0.45)
    static let surface = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let surfaceWarm = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let border = Color.black.opacity(0.08)
}

struct KeepCleanBrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(KeepCleanPalette.surfaceWarm)

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .strokeBorder(KeepCleanPalette.border, lineWidth: max(1, size * 0.018))

            RoundedRectangle(cornerRadius: size * 0.14, style: .continuous)
                .strokeBorder(KeepCleanPalette.ink.opacity(0.70), lineWidth: size * 0.04)
                .frame(width: size * 0.56, height: size * 0.38)
                .offset(y: size * 0.02)

            VStack(spacing: size * 0.045) {
                HStack(spacing: size * 0.045) {
                    key(size: size * 0.075)
                    key(size: size * 0.075)
                    key(size: size * 0.075)
                }

                RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                    .fill(KeepCleanPalette.blue)
                    .frame(width: size * 0.28, height: size * 0.07)
            }
            .offset(y: size * 0.02)

            KeepCleanSparkle()
                .fill(KeepCleanPalette.orange)
                .frame(width: size * 0.14, height: size * 0.14)
                .offset(x: size * 0.22, y: -size * 0.18)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.08), radius: size * 0.06, x: 0, y: size * 0.03)
        .accessibilityHidden(true)
    }

    private func key(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(KeepCleanPalette.ink.opacity(0.18))
            .frame(width: size, height: size)
    }
}

private struct KeepCleanSparkle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: center.x + rect.width * 0.18, y: center.y - rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x + rect.width * 0.18, y: center.y + rect.height * 0.18))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: center.x - rect.width * 0.18, y: center.y + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.addLine(to: CGPoint(x: center.x - rect.width * 0.18, y: center.y - rect.height * 0.18))
        path.closeSubpath()
        return path
    }
}
