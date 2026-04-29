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
    let shell = NSBezierPath(
        roundedRect: canvas.insetBy(dx: u(64), dy: u(64)),
        xRadius: u(226),
        yRadius: u(226)
    )

    NSGraphicsContext.current?.saveGraphicsState()
    shell.addClip()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.030, green: 0.035, blue: 0.050, alpha: 1.0),
        NSColor(calibratedRed: 0.075, green: 0.086, blue: 0.118, alpha: 1.0),
        NSColor(calibratedRed: 0.115, green: 0.090, blue: 0.060, alpha: 1.0)
    ])?.draw(in: canvas, angle: 318)

    NSColor(calibratedRed: 0.35, green: 0.42, blue: 0.58, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: NSRect(x: u(94), y: u(560), width: u(840), height: u(430))).fill()

    NSColor(calibratedRed: 0.78, green: 0.62, blue: 0.40, alpha: 0.13).setFill()
    NSBezierPath(ovalIn: NSRect(x: u(-70), y: u(-60), width: u(820), height: u(520))).fill()

    NSGraphicsContext.current?.restoreGraphicsState()

    let outerLine = NSBezierPath(
        roundedRect: canvas.insetBy(dx: u(84), dy: u(84)),
        xRadius: u(204),
        yRadius: u(204)
    )
    outerLine.lineWidth = u(11)
    NSColor(calibratedRed: 0.86, green: 0.78, blue: 0.64, alpha: 0.24).setStroke()
    outerLine.stroke()

    let plateRect = NSRect(x: u(252), y: u(238), width: u(520), height: u(520))
    let plate = NSBezierPath(roundedRect: plateRect, xRadius: u(118), yRadius: u(118))

    NSGraphicsContext.current?.saveGraphicsState()
    let plateShadow = NSShadow()
    plateShadow.shadowBlurRadius = u(38)
    plateShadow.shadowOffset = NSSize(width: 0, height: -u(18))
    plateShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
    plateShadow.set()
    NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.82, alpha: 0.075).setFill()
    plate.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    let plateStroke = NSBezierPath(roundedRect: plateRect, xRadius: u(118), yRadius: u(118))
    plateStroke.lineWidth = u(7)
    NSColor(calibratedRed: 0.92, green: 0.86, blue: 0.73, alpha: 0.22).setStroke()
    plateStroke.stroke()

    let gold = NSColor(calibratedRed: 0.86, green: 0.73, blue: 0.52, alpha: 1)
    let ivory = NSColor(calibratedRed: 0.94, green: 0.93, blue: 0.88, alpha: 1)
    let mist = NSColor(calibratedRed: 0.66, green: 0.73, blue: 0.84, alpha: 1)

    func strokePath(_ path: NSBezierPath, color: NSColor, width: CGFloat, alpha: CGFloat = 1) {
        path.lineWidth = width
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.withAlphaComponent(alpha).setStroke()
        path.stroke()
    }

    let orbit = NSBezierPath()
    orbit.move(to: NSPoint(x: u(262), y: u(430)))
    orbit.curve(
        to: NSPoint(x: u(760), y: u(596)),
        controlPoint1: NSPoint(x: u(372), y: u(682)),
        controlPoint2: NSPoint(x: u(620), y: u(718))
    )
    strokePath(orbit, color: gold, width: u(18), alpha: 0.88)

    let counterOrbit = NSBezierPath()
    counterOrbit.move(to: NSPoint(x: u(734), y: u(372)))
    counterOrbit.curve(
        to: NSPoint(x: u(308), y: u(646)),
        controlPoint1: NSPoint(x: u(612), y: u(210)),
        controlPoint2: NSPoint(x: u(372), y: u(292))
    )
    strokePath(counterOrbit, color: mist, width: u(12), alpha: 0.46)

    let axis = NSBezierPath()
    axis.move(to: NSPoint(x: u(308), y: u(326)))
    axis.line(to: NSPoint(x: u(718), y: u(326)))
    strokePath(axis, color: ivory, width: u(10), alpha: 0.72)

    let verticalAxis = NSBezierPath()
    verticalAxis.move(to: NSPoint(x: u(308), y: u(326)))
    verticalAxis.line(to: NSPoint(x: u(308), y: u(676)))
    strokePath(verticalAxis, color: ivory, width: u(10), alpha: 0.72)

    func node(center: NSPoint, radius: CGFloat, fill: NSColor, stroke: NSColor, strokeWidth: CGFloat) {
        let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = u(16)
        shadow.shadowOffset = NSSize(width: 0, height: -u(4))
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
        shadow.set()
        fill.setFill()
        NSBezierPath(ovalIn: rect).fill()
        NSGraphicsContext.current?.restoreGraphicsState()

        let outline = NSBezierPath(ovalIn: rect.insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2))
        outline.lineWidth = strokeWidth
        stroke.setStroke()
        outline.stroke()
    }

    node(
        center: NSPoint(x: u(308), y: u(326)),
        radius: u(34),
        fill: gold,
        stroke: NSColor.white.withAlphaComponent(0.48),
        strokeWidth: u(6)
    )

    node(
        center: NSPoint(x: u(512), y: u(512)),
        radius: u(46),
        fill: ivory.withAlphaComponent(0.95),
        stroke: gold.withAlphaComponent(0.72),
        strokeWidth: u(7)
    )

    node(
        center: NSPoint(x: u(718), y: u(596)),
        radius: u(30),
        fill: mist.withAlphaComponent(0.88),
        stroke: NSColor.white.withAlphaComponent(0.38),
        strokeWidth: u(5)
    )

    let fineMark = NSBezierPath()
    fineMark.move(to: NSPoint(x: u(688), y: u(682)))
    fineMark.line(to: NSPoint(x: u(742), y: u(682)))
    fineMark.line(to: NSPoint(x: u(742), y: u(628)))
    strokePath(fineMark, color: gold, width: u(9), alpha: 0.70)

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
