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

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = size / 1024

    func r(_ value: CGFloat) -> CGFloat {
        value * scale
    }

    let base = NSBezierPath(roundedRect: rect.insetBy(dx: r(72), dy: r(72)), xRadius: r(220), yRadius: r(220))
    NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.105, alpha: 1).setFill()
    base.fill()

    let glow = NSBezierPath(ovalIn: NSRect(x: r(118), y: r(556), width: r(790), height: r(330)))
    NSColor(calibratedRed: 0.11, green: 0.55, blue: 0.95, alpha: 0.18).setFill()
    glow.fill()

    let snapRing = NSBezierPath(roundedRect: rect.insetBy(dx: r(116), dy: r(116)), xRadius: r(176), yRadius: r(176))
    snapRing.lineWidth = r(30)
    NSColor(calibratedRed: 0.22, green: 0.95, blue: 0.45, alpha: 0.95).setStroke()
    snapRing.stroke()

    func window(_ frame: NSRect, color: NSColor) {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = r(24)
        shadow.shadowOffset = NSSize(width: 0, height: -r(10))
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.set()

        let path = NSBezierPath(roundedRect: frame, xRadius: r(34), yRadius: r(34))
        color.setFill()
        path.fill()

        NSGraphicsContext.current?.restoreGraphicsState()
        NSGraphicsContext.current?.saveGraphicsState()

        let titleBar = NSBezierPath(
            roundedRect: NSRect(x: frame.minX, y: frame.maxY - r(82), width: frame.width, height: r(82)),
            xRadius: r(34),
            yRadius: r(34)
        )
        NSColor.white.withAlphaComponent(0.16).setFill()
        titleBar.fill()

        for i in 0..<3 {
            NSColor.white.withAlphaComponent(0.55).setFill()
            NSBezierPath(ovalIn: NSRect(x: frame.minX + r(34 + CGFloat(i) * 42), y: frame.maxY - r(54), width: r(18), height: r(18))).fill()
        }

        let outline = NSBezierPath(roundedRect: frame, xRadius: r(34), yRadius: r(34))
        outline.lineWidth = r(10)
        NSColor.white.withAlphaComponent(0.55).setStroke()
        outline.stroke()
    }

    NSGraphicsContext.current?.saveGraphicsState()
    window(
        NSRect(x: r(250), y: r(438), width: r(524), height: r(304)),
        color: NSColor(calibratedRed: 0.17, green: 0.33, blue: 0.92, alpha: 1)
    )
    window(
        NSRect(x: r(178), y: r(286), width: r(336), height: r(248)),
        color: NSColor(calibratedRed: 0.12, green: 0.76, blue: 0.53, alpha: 1)
    )
    window(
        NSRect(x: r(510), y: r(246), width: r(336), height: r(248)),
        color: NSColor(calibratedRed: 0.92, green: 0.36, blue: 0.32, alpha: 1)
    )
    NSGraphicsContext.current?.restoreGraphicsState()

    let verticalGuide = NSBezierPath()
    verticalGuide.move(to: NSPoint(x: r(164), y: r(232)))
    verticalGuide.line(to: NSPoint(x: r(164), y: r(790)))
    verticalGuide.lineWidth = r(22)
    verticalGuide.lineCapStyle = .round
    NSColor(calibratedRed: 0.23, green: 0.98, blue: 0.46, alpha: 1).setStroke()
    verticalGuide.stroke()

    let horizontalGuide = NSBezierPath()
    horizontalGuide.move(to: NSPoint(x: r(164), y: r(232)))
    horizontalGuide.line(to: NSPoint(x: r(812), y: r(232)))
    horizontalGuide.lineWidth = r(22)
    horizontalGuide.lineCapStyle = .round
    NSColor(calibratedRed: 0.23, green: 0.98, blue: 0.46, alpha: 1).setStroke()
    horizontalGuide.stroke()

    NSColor(calibratedRed: 0.23, green: 0.98, blue: 0.46, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: r(132), y: r(200), width: r(64), height: r(64))).fill()

    image.unlockFocus()
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
