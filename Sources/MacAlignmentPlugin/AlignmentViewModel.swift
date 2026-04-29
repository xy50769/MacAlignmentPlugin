import AppKit
import Foundation

@MainActor
final class AlignmentViewModel: ObservableObject {
    @Published private(set) var windows: [WindowSnapshot] = []
    @Published private(set) var layouts: [LayoutTemplate] = []
    @Published var selectedWindowIDs: Set<String> = []
    @Published var selectedLayoutID: UUID?
    @Published var layoutName: String = "Workspace Layout"
    @Published var selectedPreset: SizePreset = .wide
    @Published var customWidth: Double = 1200
    @Published var customHeight: Double = 800
    @Published private(set) var hasAccessibilityPermission = false
    @Published var statusMessage: String = "Ready"

    private let accessibility = AccessibilityWindowService()
    private let layoutStore = LayoutStore()
    private var runtimeWindowsByID: [String: RuntimeWindow] = [:]

    init() {
        layouts = layoutStore.load()
        selectedLayoutID = layouts.first?.id
        refresh()
    }

    var selectedWindows: [WindowSnapshot] {
        windows.filter { selectedWindowIDs.contains($0.id) }
    }

    var selectedLayout: LayoutTemplate? {
        layouts.first { $0.id == selectedLayoutID }
    }

    var permissionDiagnostic: String {
        let bundlePath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        return "Trust: \(hasAccessibilityPermission ? "true" : "false") | PID: \(pid)\n\(bundlePath)"
    }

    func refresh() {
        let selectedSignatures = windows
            .filter { selectedWindowIDs.contains($0.id) }
            .map(stableSelectionSignature(for:))

        hasAccessibilityPermission = accessibility.isTrusted()
        let runtimeWindows = accessibility.visibleWindows()
        runtimeWindowsByID = Dictionary(uniqueKeysWithValues: runtimeWindows.map { ($0.snapshot.id, $0) })
        windows = runtimeWindows.map(\.snapshot)
        selectedWindowIDs = Set(
            windows
                .filter { selectedSignatures.contains(stableSelectionSignature(for: $0)) }
                .map(\.id)
        )
        statusMessage = "Found \(windows.count) visible windows"
    }

    func requestAccessibilityPermission() {
        accessibility.requestTrustPrompt()
        hasAccessibilityPermission = accessibility.isTrusted()
        statusMessage = "Use the macOS permission prompt, then quit and reopen this app"
    }

    func openAccessibilitySettings() {
        accessibility.openPrivacySettings()
        statusMessage = "Enable MacAlignmentPlugin in Accessibility, then quit and reopen this app"
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    func toggleSelection(for window: WindowSnapshot) {
        if selectedWindowIDs.contains(window.id) {
            selectedWindowIDs.remove(window.id)
        } else if window.isAdjustable {
            selectedWindowIDs.insert(window.id)
        }
    }

    func selectAllAdjustable() {
        selectedWindowIDs = Set(windows.filter(\.isAdjustable).map(\.id))
    }

    func clearSelection() {
        selectedWindowIDs.removeAll()
    }

    func saveCurrentLayout() {
        let chosenWindows = selectedWindows.filter(\.isAdjustable)
        guard !chosenWindows.isEmpty else {
            statusMessage = "Select at least one adjustable window before saving"
            return
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        let layout = LayoutTemplate(
            id: UUID(),
            name: layoutName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Workspace Layout",
            createdAt: Date(),
            displayDescription: NSScreen.main?.localizedName ?? "Current display",
            visibleFrame: WindowFrame(visibleFrame),
            entries: chosenWindows.map {
                LayoutEntry(
                    id: UUID(),
                    appName: $0.appName,
                    bundleIdentifier: $0.bundleIdentifier,
                    titleHint: $0.title,
                    frame: $0.frame
                )
            }
        )

        layouts.insert(layout, at: 0)
        selectedLayoutID = layout.id
        layoutStore.save(layouts)
        statusMessage = "Saved layout \"\(layout.name)\" with \(layout.entries.count) windows"
    }

    func deleteSelectedLayout() {
        guard let selectedLayoutID else { return }
        layouts.removeAll { $0.id == selectedLayoutID }
        self.selectedLayoutID = layouts.first?.id
        layoutStore.save(layouts)
        statusMessage = "Deleted layout"
    }

    func applySelectedLayout() {
        guard let layout = selectedLayout else {
            statusMessage = "Choose a layout first"
            return
        }

        let selectedRuntimeWindows = selectedWindowIDs.compactMap { runtimeWindowsByID[$0] }
        guard !selectedRuntimeWindows.isEmpty else {
            statusMessage = "Select at least one adjustable window"
            return
        }

        let assignments = match(layout: layout, to: selectedRuntimeWindows)
        var appliedCount = 0
        for (runtimeWindow, entry) in assignments {
            if accessibility.apply(frame: entry.frame.cgRect, to: runtimeWindow) {
                appliedCount += 1
            }
        }

        statusMessage = "Applied \(appliedCount) of \(selectedRuntimeWindows.count) selected windows"
        refresh()
    }

    func resizeSelectedToPreset() {
        resizeSelected(to: selectedPreset.size)
    }

    func resizeSelectedToCustomSize() {
        resizeSelected(to: CGSize(width: customWidth, height: customHeight))
    }

    private func resizeSelected(to size: CGSize) {
        let selectedRuntimeWindows = selectedWindowIDs.compactMap { runtimeWindowsByID[$0] }
        var resizedCount = 0
        for runtimeWindow in selectedRuntimeWindows {
            if accessibility.resize(to: size, runtimeWindow: runtimeWindow) {
                resizedCount += 1
            }
        }

        statusMessage = "Resized \(resizedCount) windows to \(Int(size.width)) x \(Int(size.height))"
        refresh()
    }

    private func match(layout: LayoutTemplate, to runtimeWindows: [RuntimeWindow]) -> [(RuntimeWindow, LayoutEntry)] {
        var unusedEntries = layout.entries
        var assignments: [(RuntimeWindow, LayoutEntry)] = []

        for runtimeWindow in runtimeWindows {
            guard let index = bestEntryIndex(for: runtimeWindow.snapshot, in: unusedEntries) else {
                continue
            }
            let entry = unusedEntries.remove(at: index)
            assignments.append((runtimeWindow, entry))
        }

        return assignments
    }

    private func bestEntryIndex(for window: WindowSnapshot, in entries: [LayoutEntry]) -> Int? {
        if let exact = entries.firstIndex(where: {
            $0.bundleIdentifier == window.bundleIdentifier && $0.titleHint == window.title
        }) {
            return exact
        }

        if let fuzzy = entries.firstIndex(where: {
            $0.bundleIdentifier == window.bundleIdentifier
                && (!$0.titleHint.isEmpty && (window.title.contains($0.titleHint) || $0.titleHint.contains(window.title)))
        }) {
            return fuzzy
        }

        return entries.firstIndex { $0.bundleIdentifier == window.bundleIdentifier || $0.appName == window.appName }
    }

    private func stableSelectionSignature(for window: WindowSnapshot) -> String {
        "\(window.pid)-\(window.bundleIdentifier)-\(window.title)"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
