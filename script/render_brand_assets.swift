#!/usr/bin/env swift

import AppKit
import Foundation

let arguments = CommandLine.arguments.dropFirst()
let outputDirectory = URL(fileURLWithPath: arguments.first ?? FileManager.default.currentDirectoryPath)
let sourceURL = URL(fileURLWithPath: arguments.dropFirst().first ?? "KeepClean/Resources/brand-mark.png")
let iconSetDirectory = outputDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let markURL = outputDirectory.appendingPathComponent("brand-mark.png")

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    throw NSError(
        domain: "KeepCleanBrand",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Unable to load source image at \(sourceURL.path)"]
    )
}

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
        throw NSError(domain: "KeepCleanBrand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    let canvas = CGRect(origin: .zero, size: NSSize(width: size, height: size))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    graphicsContext.cgContext.clear(canvas)
    sourceImage.draw(in: canvas, from: .zero, operation: .copy, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "KeepCleanBrand", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }

    try png.write(to: iconSetDirectory.appendingPathComponent(fileName))
}

for (fileName, size) in sizes {
    try writePNG(named: fileName, size: size)
}

try FileManager.default.removeItemIfExists(at: markURL)
try FileManager.default.copyItem(at: sourceURL, to: markURL)

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }
        try removeItem(at: url)
    }
}
