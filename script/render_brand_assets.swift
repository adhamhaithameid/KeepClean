#!/usr/bin/env swift

import AppKit
import Foundation

struct BrandColor {
    static let ink = NSColor(calibratedRed: 0.11, green: 0.15, blue: 0.21, alpha: 1.0)
    static let sky = NSColor(calibratedRed: 0.20, green: 0.49, blue: 0.97, alpha: 1.0)
    static let skySoft = NSColor(calibratedRed: 0.80, green: 0.89, blue: 1.00, alpha: 1.0)
    static let amber = NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.25, alpha: 1.0)
    static let cream = NSColor(calibratedRed: 0.99, green: 0.97, blue: 0.92, alpha: 1.0)
    static let mist = NSColor(calibratedRed: 0.94, green: 0.96, blue: 1.00, alpha: 1.0)
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

func sweepPath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
    path.curve(
        to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY + rect.height * 0.24),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY - rect.height * 0.10),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.02)
    )
    path.line(to: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.minY + rect.height * 0.46))
    path.curve(
        to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.05),
        controlPoint1: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.maxY + rect.height * 0.05),
        controlPoint2: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY + rect.height * 0.03)
    )
    path.close()
    return path
}

func sparklePath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
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
    points.dropFirst().forEach { path.line(to: $0) }
    path.close()
    return path
}

func writePNG(named fileName: String, size: CGFloat) throws {
    let canvasSize = NSSize(width: size, height: size)
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

    let canvas = CGRect(origin: .zero, size: canvasSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.clear(canvas)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 0.12)
    shadow.shadowBlurRadius = size * 0.10
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.04)
    shadow.set()

    let outer = NSBezierPath(roundedRect: canvas.insetBy(dx: size * 0.06, dy: size * 0.06), xRadius: size * 0.20, yRadius: size * 0.20)
    let outerGradient = NSGradient(colors: [BrandColor.cream, BrandColor.mist])!
    outerGradient.draw(in: outer, angle: -35)

    NSColor.white.withAlphaComponent(0.85).setStroke()
    outer.lineWidth = size * 0.025
    outer.stroke()

    let innerRect = canvas.insetBy(dx: size * 0.17, dy: size * 0.17)
    let inner = NSBezierPath(roundedRect: innerRect, xRadius: size * 0.16, yRadius: size * 0.16)
    let innerGradient = NSGradient(colors: [NSColor.white.withAlphaComponent(0.98), BrandColor.skySoft])!
    innerGradient.draw(in: inner, angle: -35)

    NSColor(calibratedWhite: 0.0, alpha: 0.10).setStroke()
    inner.lineWidth = size * 0.02
    inner.stroke()

    let sweepRect = CGRect(
        x: canvas.minX + size * 0.20,
        y: canvas.minY + size * 0.26,
        width: size * 0.56,
        height: size * 0.44
    )
    BrandColor.sky.setFill()
    sweepPath(in: sweepRect).fill()

    let shineRect = CGRect(
        x: canvas.minX + size * 0.34,
        y: canvas.minY + size * 0.34,
        width: size * 0.32,
        height: size * 0.22
    )
    NSColor.white.withAlphaComponent(0.55).setFill()
    sweepPath(in: shineRect).fill()

    let sparkleRect = CGRect(
        x: canvas.minX + size * 0.67,
        y: canvas.minY + size * 0.67,
        width: size * 0.14,
        height: size * 0.14
    )
    BrandColor.amber.setFill()
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
try FileManager.default.copyItem(
    at: iconSetDirectory.appendingPathComponent("icon_512x512@2x.png"),
    to: markURL
)

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else {
            return
        }

        try removeItem(at: url)
    }
}
