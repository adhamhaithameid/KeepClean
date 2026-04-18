import AppKit
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
        Group {
            if let url = Bundle.main.url(forResource: "brand-mark", withExtension: "png"),
               let image = NSImage(contentsOf: url) {
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
                            .foregroundStyle(KeepCleanPalette.ink)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .strokeBorder(KeepCleanPalette.border, lineWidth: 1)
                    }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
