#!/usr/bin/env swift

import AppKit
import Foundation

struct BrandColor {
    static let ink = NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.22, alpha: 1.0)
    static let mutedInk = NSColor(calibratedRed: 0.40, green: 0.43, blue: 0.49, alpha: 1.0)
    static let blue = NSColor(calibratedRed: 0.18, green: 0.46, blue: 0.92, alpha: 1.0)
    static let orange = NSColor(calibratedRed: 0.95, green: 0.52, blue: 0.19, alpha: 1.0)
    static let surface = NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
    static let border = NSColor(calibratedWhite: 0.0, alpha: 0.08)
}

let arguments = CommandLine.arguments
let outputDirectory = URL(fileURLWithPath: arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
let iconSetDirectory = outputDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let markURL = outputDirectory.appendingPathComponent("brand-mark.png")

try FileManager.default.createDirectory(at: iconSetDirectory, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func sparklePath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let points = [
        CGPoint(x: center.x, y: rect.minY),
        CGPoint(x: center.x + rect.width * 0.18, y: center.y - rect.height * 0.18),
        CGPoint(x: rect.maxX, y: center.y),
        CGPoint(x: center.x + rect.width * 0.18, y: center.y + rect.height * 0.18),
        CGPoint(x: center.x, y: rect.maxY),
        CGPoint(x: center.x - rect.width * 0.18, y: center.y + rect.height * 0.18),
        CGPoint(x: rect.minX, y: center.y),
        CGPoint(x: center.x - rect.width * 0.18, y: center.y - rect.height * 0.18),
    ]
    path.move(to: points[0])
    points.dropFirst().forEach { path.line(to: $0) }
    path.close()
    return path
}

func keyPath(in rect: CGRect) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.32, yRadius: rect.height * 0.32)
}

func writePNG(named fileName: String, size: CGFloat) throws {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        throw NSError(domain: "KeepCleanBrand", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    let canvas = CGRect(origin: .zero, size: NSSize(width: size, height: size))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.clear(canvas)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.08)
    shadow.shadowBlurRadius = size * 0.06
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.03)
    shadow.set()

    let tileRect = canvas.insetBy(dx: size * 0.06, dy: size * 0.06)
    let tile = NSBezierPath(roundedRect: tileRect, xRadius: size * 0.16, yRadius: size * 0.16)
    BrandColor.surface.setFill()
    tile.fill()
    BrandColor.border.setStroke()
    tile.lineWidth = max(1, size * 0.018)
    tile.stroke()

    let keyboardRect = CGRect(
        x: canvas.midX - size * 0.28,
        y: canvas.midY - size * 0.15,
        width: size * 0.56,
        height: size * 0.38
    )
    let keyboard = NSBezierPath(roundedRect: keyboardRect, xRadius: size * 0.09, yRadius: size * 0.09)
    BrandColor.ink.withAlphaComponent(0.70).setStroke()
    keyboard.lineWidth = size * 0.04
    keyboard.stroke()

    let keySize = size * 0.075
    let keyRowY = keyboardRect.midY + size * 0.02
    let keySpacing = size * 0.045
    let keyStartX = canvas.midX - keySize - keySpacing
    for index in 0..<3 {
        let rect = CGRect(
            x: keyStartX + CGFloat(index) * (keySize + keySpacing),
            y: keyRowY,
            width: keySize,
            height: keySize
        )
        BrandColor.ink.withAlphaComponent(0.18).setFill()
        keyPath(in: rect).fill()
    }

    let barRect = CGRect(
        x: canvas.midX - size * 0.14,
        y: keyboardRect.minY + size * 0.08,
        width: size * 0.28,
        height: size * 0.07
    )
    BrandColor.blue.setFill()
    keyPath(in: barRect).fill()

    let sparkleRect = CGRect(
        x: canvas.midX + size * 0.15,
        y: canvas.midY + size * 0.16,
        width: size * 0.14,
        height: size * 0.14
    )
    BrandColor.orange.setFill()
    sparklePath(in: sparkleRect).fill()

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "KeepCleanBrand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }

    try png.write(to: iconSetDirectory.appendingPathComponent(fileName))
}

for (fileName, size) in sizes {
    try writePNG(named: fileName, size: size)
}

try FileManager.default.removeItemIfExists(at: markURL)
try FileManager.default.copyItem(at: iconSetDirectory.appendingPathComponent("icon_512x512@2x.png"), to: markURL)

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }
        try removeItem(at: url)
    }
}
