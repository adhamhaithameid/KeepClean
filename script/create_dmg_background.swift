#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: create_dmg_background.swift <output-path>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 700, height: 420)
let rect = NSRect(origin: .zero, size: size)
let image = NSImage(size: size)

image.lockFocus()

NSColor(calibratedRed: 0.95, green: 0.98, blue: 1.0, alpha: 1).setFill()
rect.fill()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.93, green: 0.98, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 1)
])!
gradient.draw(in: rect, angle: 315)

let panelRect = NSRect(x: 24, y: 24, width: 652, height: 372)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 28, yRadius: 28)
NSColor(calibratedWhite: 1.0, alpha: 0.92).setFill()
panelPath.fill()

NSColor(calibratedWhite: 0.83, alpha: 1.0).setStroke()
panelPath.lineWidth = 1
panelPath.stroke()

let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.08)
shadow.shadowOffset = NSSize(width: 0, height: -8)
shadow.shadowBlurRadius = 20
shadow.set()

let title = "Drag KeepClean to Applications"
let titleStyle = NSMutableParagraphStyle()
titleStyle.alignment = .center
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 30, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.15, alpha: 1),
    .paragraphStyle: titleStyle
]
title.draw(in: NSRect(x: 100, y: 304, width: 500, height: 44), withAttributes: titleAttributes)

let subtitle = "Then open the app from Applications. If macOS asks for approval, KeepClean can open Privacy & Security for you."
let subtitleStyle = NSMutableParagraphStyle()
subtitleStyle.alignment = .center
subtitleStyle.lineBreakMode = .byWordWrapping
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.38, alpha: 1),
    .paragraphStyle: subtitleStyle
]
subtitle.draw(in: NSRect(x: 88, y: 254, width: 524, height: 52), withAttributes: subtitleAttributes)

let arrowPath = NSBezierPath()
arrowPath.lineWidth = 10
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.move(to: NSPoint(x: 282, y: 160))
arrowPath.curve(
    to: NSPoint(x: 424, y: 160),
    controlPoint1: NSPoint(x: 332, y: 176),
    controlPoint2: NSPoint(x: 378, y: 176)
)
arrowPath.line(to: NSPoint(x: 402, y: 182))
arrowPath.move(to: NSPoint(x: 424, y: 160))
arrowPath.line(to: NSPoint(x: 402, y: 138))
NSColor(calibratedRed: 0.11, green: 0.55, blue: 0.92, alpha: 0.7).setStroke()
arrowPath.stroke()

let leftCaption = "KeepClean"
let rightCaption = "Applications"
let captionAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.32, alpha: 1)
]
leftCaption.draw(in: NSRect(x: 126, y: 84, width: 120, height: 18), withAttributes: captionAttributes)
rightCaption.draw(in: NSRect(x: 448, y: 84, width: 120, height: 18), withAttributes: captionAttributes)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmapRep = NSBitmapImageRep(data: tiffData),
    let pngData = bitmapRep.representation(using: .png, properties: [:])
else {
    fputs("Failed to render DMG background.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)
