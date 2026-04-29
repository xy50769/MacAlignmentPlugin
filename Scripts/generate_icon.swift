#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate_icon.swift <output.icns>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let fileManager = FileManager.default
let tempRoot = fileManager.temporaryDirectory.appendingPathComponent("MacAlignmentPluginIcon-\(UUID().uuidString)", isDirectory: true)
let iconsetURL = tempRoot.appendingPathComponent("AppIcon.iconset", isDirectory: true)

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let scale = size / 1024
    func u(_ value: CGFloat) -> CGFloat { value * scale }

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let outer = NSBezierPath(roundedRect: canvas.insetBy(dx: u(64), dy: u(64)), xRadius: u(220), yRadius: u(220))

    NSGraphicsContext.current?.saveGraphicsState()
    outer.addClip()

    let backgroundGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.035, green: 0.047, blue: 0.070, alpha: 1),
        NSColor(calibratedRed: 0.055, green: 0.095, blue: 0.125, alpha: 1),
        NSColor(calibratedRed: 0.020, green: 0.026, blue: 0.040, alpha: 1)
    ])
    backgroundGradient?.draw(in: canvas, angle: 315)

    let cyanGlow = NSBezierPath(ovalIn: NSRect(x: u(110), y: u(610), width: u(760), height: u(360)))
    NSColor(calibratedRed: 0.11, green: 0.58, blue: 0.90, alpha: 0.20).setFill()
    cyanGlow.fill()

    let greenGlow = NSBezierPath(ovalIn: NSRect(x: u(70), y: u(100), width: u(680), height: u(420)))
    NSColor(calibratedRed: 0.12, green: 0.88, blue: 0.52, alpha: 0.16).setFill()
    greenGlow.fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    let outerStroke = NSBezierPath(roundedRect: canvas.insetBy(dx: u(82), dy: u(82)), xRadius: u(198), yRadius: u(198))
    outerStroke.lineWidth = u(12)
    NSColor.white.withAlphaComponent(0.18).setStroke()
    outerStroke.stroke()

    let anchorX = u(214)
    let anchorY = u(238)
    let guideColor = NSColor(calibratedRed: 0.23, green: 0.96, blue: 0.55, alpha: 1)

    let verticalGuide = NSBezierPath()
    verticalGuide.move(to: NSPoint(x: anchorX, y: anchorY))
    verticalGuide.line(to: NSPoint(x: anchorX, y: u(778)))
    verticalGuide.lineWidth = u(20)
    verticalGuide.lineCapStyle = .round
    guideColor.setStroke()
    verticalGuide.stroke()

    let horizontalGuide = NSBezierPath()
    horizontalGuide.move(to: NSPoint(x: anchorX, y: anchorY))
    horizontalGuide.line(to: NSPoint(x: u(806), y: anchorY))
    horizontalGuide.lineWidth = u(20)
    horizontalGuide.lineCapStyle = .round
    guideColor.setStroke()
    horizontalGuide.stroke()

    guideColor.setFill()
    NSBezierPath(ovalIn: NSRect(x: anchorX - u(29), y: anchorY - u(29), width: u(58), height: u(58))).fill()

    func drawWindow(_ frame: NSRect, active: Bool) {
        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = u(active ? 34 : 22)
        shadow.shadowOffset = NSSize(width: 0, height: -u(active ? 16 : 10))
        shadow.shadowColor = NSColor.black.withAlphaComponent(active ? 0.34 : 0.24)
        shadow.set()

        let shape = NSBezierPath(roundedRect: frame, xRadius: u(42), yRadius: u(42))
        NSColor(calibratedWhite: active ? 0.98 : 0.88, alpha: active ? 0.24 : 0.15).setFill()
        shape.fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        let clipped = NSBezierPath(roundedRect: frame, xRadius: u(42), yRadius: u(42))
        NSGraphicsContext.current?.saveGraphicsState()
        clipped.addClip()
        NSGradient(colors: [
            NSColor.white.withAlphaComponent(active ? 0.30 : 0.18),
            NSColor.white.withAlphaComponent(active ? 0.10 : 0.07)
        ])?.draw(in: frame, angle: 90)

        NSColor.white.withAlphaComponent(active ? 0.20 : 0.12).setFill()
        NSRect(x: frame.minX, y: frame.maxY - u(78), width: frame.width, height: u(78)).fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        let stroke = NSBezierPath(roundedRect: frame, xRadius: u(42), yRadius: u(42))
        stroke.lineWidth = u(active ? 10 : 8)
        NSColor.white.withAlphaComponent(active ? 0.72 : 0.44).setStroke()
        stroke.stroke()

        for index in 0..<3 {
            NSColor.white.withAlphaComponent(active ? 0.62 : 0.38).setFill()
            NSBezierPath(
                ovalIn: NSRect(
                    x: frame.minX + u(34 + CGFloat(index) * 38),
                    y: frame.maxY - u(49),
                    width: u(14),
                    height: u(14)
                )
            ).fill()
        }
    }

    drawWindow(NSRect(x: u(304), y: u(468), width: u(498), height: u(286)), active: true)
    drawWindow(NSRect(x: u(236), y: u(316), width: u(322), height: u(226)), active: false)
    drawWindow(NSRect(x: u(548), y: u(288), width: u(300), height: u(220)), active: false)

    let sparkle = NSBezierPath()
    sparkle.move(to: NSPoint(x: u(790), y: u(770)))
    sparkle.line(to: NSPoint(x: u(822), y: u(822)))
    sparkle.move(to: NSPoint(x: u(822), y: u(770)))
    sparkle.line(to: NSPoint(x: u(790), y: u(822)))
    sparkle.lineWidth = u(12)
    sparkle.lineCapStyle = .round
    NSColor.white.withAlphaComponent(0.60).setStroke()
    sparkle.stroke()

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MacAlignmentPluginIcon", code: 1)
    }
    try png.write(to: url, options: .atomic)
}

let iconFiles: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for iconFile in iconFiles {
    try writePNG(drawIcon(size: iconFile.pixels), to: iconsetURL.appendingPathComponent(iconFile.name))
}

try? fileManager.removeItem(at: outputURL)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

try? fileManager.removeItem(at: tempRoot)

if process.terminationStatus != 0 {
    exit(process.terminationStatus)
}
