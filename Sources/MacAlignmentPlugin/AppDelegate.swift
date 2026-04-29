import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let viewModel = AlignmentViewModel()
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hideDockIcon()
        createStatusItem()
        showPanel()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        viewModel.refresh()
    }

    func windowWillClose(_ notification: Notification) {
        hidePanel()
    }

    @objc private func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "MacAlignmentPlugin")
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        statusItem = item
    }

    private func showPanel() {
        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }
        showDockIcon()
        viewModel.refresh()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        hideDockIcon()
    }

    private func showDockIcon() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func hideDockIcon() {
        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func makePanel() -> NSPanel {
        let hostingController = NSHostingController(
            rootView: ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 1040, minHeight: 740)
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "MacAlignmentPlugin"
        panel.contentViewController = hostingController
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = false
        panel.minSize = NSSize(width: 1040, height: 740)
        panel.delegate = self
        panel.center()
        return panel
    }
}
