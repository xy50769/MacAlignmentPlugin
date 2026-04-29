import AppKit
import ApplicationServices
import Foundation

final class AccessibilityWindowService {
    private let minimumUsefulWindowSize = CGSize(width: 240, height: 180)

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestTrustPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func visibleWindows() -> [RuntimeWindow] {
        let visibleCGWindows = currentOnScreenWindows()
        let runningAppsByPID = Dictionary(
            uniqueKeysWithValues: NSWorkspace.shared.runningApplications.compactMap { app -> (pid_t, NSRunningApplication)? in
                guard app.activationPolicy == .regular else { return nil }
                return (app.processIdentifier, app)
            }
        )

        let cgRuntimeWindows: [RuntimeWindow] = visibleCGWindows.compactMap { cgWindow in
            guard let app = runningAppsByPID[cgWindow.pid] else { return nil }
            guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }

            let appElement = AXUIElementCreateApplication(cgWindow.pid)
            let matchingElement = findMatchingAXWindow(
                appElement: appElement,
                cgTitle: cgWindow.title,
                cgBounds: cgWindow.bounds
            )
            let axState = accessibilityState(for: matchingElement)
            let bundleID = app.bundleIdentifier ?? "pid.\(cgWindow.pid)"
            let title = axState.title.nilIfEmpty ?? cgWindow.title.nilIfEmpty ?? "Untitled"
            let finalFrame = axState.frame ?? cgWindow.bounds
            guard isUsefulWindowFrame(finalFrame) else {
                return nil
            }

            let id = stableID(
                pid: cgWindow.pid,
                windowNumber: cgWindow.windowNumber,
                bundleIdentifier: bundleID,
                title: title
            )
            let skipReason = axState.skipReason

            let snapshot = WindowSnapshot(
                id: id,
                pid: cgWindow.pid,
                windowNumber: cgWindow.windowNumber,
                appName: app.localizedName ?? cgWindow.ownerName,
                bundleIdentifier: bundleID,
                title: title,
                frame: WindowFrame(finalFrame),
                isAdjustable: matchingElement != nil && skipReason == nil,
                skipReason: skipReason
            )

            return RuntimeWindow(snapshot: snapshot, element: matchingElement)
        }

        let axRuntimeWindows = accessibleAppWindows(runningApps: Array(runningAppsByPID.values))
        return deduplicated(cgRuntimeWindows + axRuntimeWindows)
        .sorted {
            if $0.snapshot.appName == $1.snapshot.appName {
                return $0.snapshot.title.localizedCaseInsensitiveCompare($1.snapshot.title) == .orderedAscending
            }
            return $0.snapshot.appName.localizedCaseInsensitiveCompare($1.snapshot.appName) == .orderedAscending
        }
    }

    func apply(frame: CGRect, to runtimeWindow: RuntimeWindow) -> Bool {
        guard let element = runtimeWindow.element, runtimeWindow.snapshot.isAdjustable else {
            return false
        }

        let clampedFrame = clampedToVisibleScreen(frame)
        var position = clampedFrame.origin
        var size = clampedFrame.size
        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return false
        }

        let positionResult = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, positionValue)
        let sizeResult = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        return positionResult == .success && sizeResult == .success
    }

    func resize(to size: CGSize, runtimeWindow: RuntimeWindow) -> Bool {
        var frame = runtimeWindow.snapshot.frame.cgRect
        frame.size = size
        return apply(frame: frame, to: runtimeWindow)
    }

    private func currentOnScreenWindows() -> [CGWindowInfo] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { dictionary in
            guard let layer = dictionary[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = dictionary[kCGWindowOwnerPID as String] as? pid_t,
                  let windowNumber = dictionary[kCGWindowNumber as String] as? Int,
                  let ownerName = dictionary[kCGWindowOwnerName as String] as? String,
                  let boundsDictionary = dictionary[kCGWindowBounds as String] as? [String: CGFloat],
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary as CFDictionary) else {
                return nil
            }

            let title = dictionary[kCGWindowName as String] as? String
            guard isUsefulWindowFrame(bounds) else { return nil }
            return CGWindowInfo(
                pid: pid,
                windowNumber: windowNumber,
                ownerName: ownerName,
                title: title ?? "",
                bounds: bounds
            )
        }
    }

    private func accessibleAppWindows(runningApps: [NSRunningApplication]) -> [RuntimeWindow] {
        runningApps.flatMap { app -> [RuntimeWindow] in
            guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                return []
            }

            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            guard let windows = copyAttribute(appElement, attribute: kAXWindowsAttribute) as? [AXUIElement] else {
                return []
            }

            return windows.enumerated().compactMap { index, window in
                let state = accessibilityState(for: window)
                guard let frame = state.frame, isUsefulWindowFrame(frame) else {
                    return nil
                }

                let bundleID = app.bundleIdentifier ?? "pid.\(app.processIdentifier)"
                let title = state.title.nilIfEmpty ?? "Untitled"
                guard !isFinderDesktopWindow(bundleIdentifier: bundleID, title: title, frame: frame) else {
                    return nil
                }

                let snapshot = WindowSnapshot(
                    id: stableID(
                        pid: app.processIdentifier,
                        windowNumber: -index - 1,
                        bundleIdentifier: bundleID,
                        title: title
                    ),
                    pid: app.processIdentifier,
                    windowNumber: -index - 1,
                    appName: app.localizedName ?? bundleID,
                    bundleIdentifier: bundleID,
                    title: title,
                    frame: WindowFrame(frame),
                    isAdjustable: state.skipReason == nil,
                    skipReason: state.skipReason
                )

                return RuntimeWindow(snapshot: snapshot, element: window)
            }
        }
    }

    private func findMatchingAXWindow(appElement: AXUIElement, cgTitle: String, cgBounds: CGRect) -> AXUIElement? {
        guard let windows = copyAttribute(appElement, attribute: kAXWindowsAttribute) as? [AXUIElement] else {
            return nil
        }

        let candidates = windows.filter { window in
            let state = accessibilityState(for: window)
            guard state.skipReason == nil || state.skipReason == "Cannot resize" else {
                return false
            }
            if cgTitle.isEmpty || cgTitle == "Untitled" {
                return true
            }
            return state.title.isEmpty
                || state.title == cgTitle
                || state.title.contains(cgTitle)
                || cgTitle.contains(state.title)
        }

        if !cgTitle.isEmpty,
           cgTitle != "Untitled",
           let exactTitle = candidates.first(where: { accessibilityState(for: $0).title == cgTitle }) {
            return exactTitle
        }

        return candidates.min { left, right in
            let leftFrame = accessibilityState(for: left).frame ?? .zero
            let rightFrame = accessibilityState(for: right).frame ?? .zero
            return frameDistance(leftFrame, cgBounds) < frameDistance(rightFrame, cgBounds)
        }
    }

    private func accessibilityState(for element: AXUIElement?) -> (title: String, frame: CGRect?, skipReason: String?) {
        guard let element else {
            return ("", nil, "No accessibility handle")
        }

        let minimized = copyAttribute(element, attribute: kAXMinimizedAttribute) as? Bool ?? false
        if minimized {
            return (windowTitle(element), windowFrame(element), "Minimized")
        }

        if let fullScreen = copyAttribute(element, attribute: "AXFullScreen") as? Bool, fullScreen {
            return (windowTitle(element), windowFrame(element), "Full screen")
        }

        guard copyAttribute(element, attribute: kAXPositionAttribute) != nil,
              copyAttribute(element, attribute: kAXSizeAttribute) != nil else {
            return (windowTitle(element), windowFrame(element), "Cannot resize")
        }

        return (windowTitle(element), windowFrame(element), nil)
    }

    private func windowTitle(_ element: AXUIElement) -> String {
        copyAttribute(element, attribute: kAXTitleAttribute) as? String ?? ""
    }

    private func windowFrame(_ element: AXUIElement) -> CGRect? {
        guard let positionAny = copyAttribute(element, attribute: kAXPositionAttribute),
              let sizeAny = copyAttribute(element, attribute: kAXSizeAttribute) else {
            return nil
        }

        let positionValue = positionAny as! AXValue
        let sizeValue = sizeAny as! AXValue
        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue, .cgPoint, &position)
        AXValueGetValue(sizeValue, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    private func copyAttribute(_ element: AXUIElement, attribute: String) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value
    }

    private func frameDistance(_ first: CGRect, _ second: CGRect) -> CGFloat {
        abs(first.origin.x - second.origin.x)
            + abs(first.origin.y - second.origin.y)
            + abs(first.width - second.width)
            + abs(first.height - second.height)
    }

    private func stableID(pid: pid_t, windowNumber: Int, bundleIdentifier: String, title: String) -> String {
        "\(pid)-\(windowNumber)-\(bundleIdentifier)-\(title)"
    }

    private func isUsefulWindowFrame(_ frame: CGRect) -> Bool {
        guard frame.width >= minimumUsefulWindowSize.width,
              frame.height >= minimumUsefulWindowSize.height else {
            return false
        }

        return NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
    }

    private func clampedToVisibleScreen(_ frame: CGRect) -> CGRect {
        guard let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(frame.origin) })
            ?? NSScreen.screens.first(where: { $0.visibleFrame.intersects(frame) }) else {
            return frame
        }

        let visibleFrame = screen.visibleFrame
        let x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - 80)
        let y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - 80)
        let maxWidth = max(80, visibleFrame.maxX - x)
        let maxHeight = max(80, visibleFrame.maxY - y)
        return CGRect(
            x: x,
            y: y,
            width: min(frame.width, maxWidth),
            height: min(frame.height, maxHeight)
        )
    }

    private func isFinderDesktopWindow(bundleIdentifier: String, title: String, frame: CGRect) -> Bool {
        guard bundleIdentifier == "com.apple.finder",
              title == "Untitled",
              frame.origin.x == 0,
              frame.origin.y == 0 else {
            return false
        }

        return NSScreen.screens.contains { screen in
            let visible = screen.visibleFrame
            return abs(frame.width - visible.width) < 80 || abs(frame.height - visible.height) < 80
        }
    }

    private func deduplicated(_ runtimeWindows: [RuntimeWindow]) -> [RuntimeWindow] {
        var seenKeys = Set<String>()
        var result: [RuntimeWindow] = []

        for runtimeWindow in runtimeWindows {
            let frame = runtimeWindow.snapshot.frame
            let key = [
                runtimeWindow.snapshot.bundleIdentifier,
                runtimeWindow.snapshot.title,
                String(Int(frame.x / 10) * 10),
                String(Int(frame.y / 10) * 10),
                String(Int(frame.width / 10) * 10),
                String(Int(frame.height / 10) * 10)
            ].joined(separator: "|")

            guard !seenKeys.contains(key) else { continue }
            seenKeys.insert(key)
            result.append(runtimeWindow)
        }

        return result
    }
}

private struct CGWindowInfo {
    let pid: pid_t
    let windowNumber: Int
    let ownerName: String
    let title: String
    let bounds: CGRect
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
