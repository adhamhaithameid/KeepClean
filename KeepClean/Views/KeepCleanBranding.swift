import SwiftUI

enum KeepCleanPalette {
    static let ink = Color(red: 0.11, green: 0.15, blue: 0.21)
    static let sky = Color(red: 0.20, green: 0.49, blue: 0.97)
    static let skySoft = Color(red: 0.80, green: 0.89, blue: 1.00)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.25)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.92)
    static let mist = Color(red: 0.94, green: 0.96, blue: 1.00)
    static let graphite = Color(red: 0.16, green: 0.19, blue: 0.25)
    static let success = Color(red: 0.20, green: 0.62, blue: 0.49)
    static let warning = Color(red: 0.90, green: 0.47, blue: 0.18)
}

struct KeepCleanBrandMark: View {
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [KeepCleanPalette.cream, KeepCleanPalette.mist],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.86), lineWidth: size * 0.02)
                .blendMode(.screen)

            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .inset(by: size * 0.09)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.96), KeepCleanPalette.skySoft.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .inset(by: size * 0.09)
                        .strokeBorder(KeepCleanPalette.ink.opacity(0.12), lineWidth: size * 0.017)
                }

            KeepCleanSweepShape()
                .fill(KeepCleanPalette.sky)
                .frame(width: size * 0.56, height: size * 0.46)
                .offset(x: -size * 0.04, y: size * 0.04)

            KeepCleanSweepShape()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.34, height: size * 0.24)
                .offset(x: size * 0.01, y: -size * 0.02)

            KeepCleanSparkleShape()
                .fill(KeepCleanPalette.amber)
                .frame(width: size * 0.18, height: size * 0.18)
                .offset(x: size * 0.22, y: -size * 0.20)
        }
        .frame(width: size, height: size)
        .shadow(color: KeepCleanPalette.ink.opacity(0.10), radius: size * 0.08, x: 0, y: size * 0.04)
        .accessibilityHidden(true)
    }
}

private struct KeepCleanSweepShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.24),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.08)
        )
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.minY + rect.height * 0.46))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.05),
            control: CGPoint(x: rect.midX - rect.width * 0.02, y: rect.maxY + rect.height * 0.06)
        )
        path.closeSubpath()
        return path
    }
}

private struct KeepCleanSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = [
            CGPoint(x: center.x, y: rect.minY),
            CGPoint(x: center.x + rect.width * 0.17, y: center.y - rect.height * 0.17),
            CGPoint(x: rect.maxX, y: center.y),
            CGPoint(x: center.x + rect.width * 0.17, y: center.y + rect.height * 0.17),
            CGPoint(x: center.x, y: rect.maxY),
            CGPoint(x: center.x - rect.width * 0.17, y: center.y + rect.height * 0.17),
            CGPoint(x: rect.minX, y: center.y),
            CGPoint(x: center.x - rect.width * 0.17, y: center.y - rect.height * 0.17),
        ]

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
