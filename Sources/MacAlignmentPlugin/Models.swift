import AppKit
import ApplicationServices
import Foundation

struct WindowFrame: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct WindowSnapshot: Identifiable, Hashable {
    let id: String
    let pid: pid_t
    let windowNumber: Int
    let appName: String
    let bundleIdentifier: String
    let title: String
    let frame: WindowFrame
    let isAdjustable: Bool
    let skipReason: String?
}

struct RuntimeWindow {
    let snapshot: WindowSnapshot
    let element: AXUIElement?
}

struct LayoutTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var displayDescription: String
    var visibleFrame: WindowFrame
    var entries: [LayoutEntry]
}

struct LayoutEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var appName: String
    var bundleIdentifier: String
    var titleHint: String
    var frame: WindowFrame
}

enum SizePreset: String, CaseIterable, Identifiable {
    case hd = "1280 x 720"
    case wide = "1440 x 900"
    case compact = "1000 x 700"
    case reading = "900 x 1100"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .hd:
            CGSize(width: 1280, height: 720)
        case .wide:
            CGSize(width: 1440, height: 900)
        case .compact:
            CGSize(width: 1000, height: 700)
        case .reading:
            CGSize(width: 900, height: 1100)
        }
    }
}
