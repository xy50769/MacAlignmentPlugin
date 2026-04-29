import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AlignmentViewModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            HStack(spacing: 0) {
                windowList
                    .frame(minWidth: 430)

                Divider()

                controls
                    .frame(width: 300)
            }

            Divider()

            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.hasAccessibilityPermission ? "checkmark.shield" : "exclamationmark.triangle")
                .foregroundStyle(viewModel.hasAccessibilityPermission ? .green : .orange)
            Text("MacAlignmentPlugin")
                .font(.headline)
            Spacer()
            Button {
                viewModel.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .padding(14)
    }

    private var windowList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Visible Windows")
                    .font(.headline)
                Spacer()
                Button("Select All") {
                    viewModel.selectAllAdjustable()
                }
                Button("Clear") {
                    viewModel.clearSelection()
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            List(viewModel.windows) { window in
                WindowRow(
                    window: window,
                    isSelected: viewModel.selectedWindowIDs.contains(window.id)
                ) {
                    viewModel.toggleSelection(for: window)
                }
            }
            .listStyle(.inset)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            permissionBox

            GroupBox("Layouts") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Layout name", text: $viewModel.layoutName)

                    Picker("Saved", selection: $viewModel.selectedLayoutID) {
                        Text("Choose layout").tag(UUID?.none)
                        ForEach(viewModel.layouts) { layout in
                            Text(layout.name).tag(Optional(layout.id))
                        }
                    }

                    HStack {
                        Button {
                            viewModel.saveCurrentLayout()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            viewModel.applySelectedLayout()
                        } label: {
                            Label("Apply", systemImage: "rectangle.on.rectangle")
                        }
                    }

                    Button(role: .destructive) {
                        viewModel.deleteSelectedLayout()
                    } label: {
                        Label("Delete Layout", systemImage: "trash")
                    }
                    .disabled(viewModel.selectedLayoutID == nil)
                }
                .padding(4)
            }

            GroupBox("Quick Size") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Preset", selection: $viewModel.selectedPreset) {
                        ForEach(SizePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }

                    Button {
                        viewModel.resizeSelectedToPreset()
                    } label: {
                        Label("Apply Preset", systemImage: "arrow.up.left.and.arrow.down.right")
                    }

                    HStack {
                        TextField("Width", value: $viewModel.customWidth, format: .number)
                        TextField("Height", value: $viewModel.customHeight, format: .number)
                    }

                    Button {
                        viewModel.resizeSelectedToCustomSize()
                    } label: {
                        Label("Apply Custom Size", systemImage: "slider.horizontal.3")
                    }
                }
                .padding(4)
            }

            Spacer()
        }
        .padding(14)
    }

    @ViewBuilder
    private var permissionBox: some View {
        if !viewModel.hasAccessibilityPermission {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use the macOS permission prompt first. If needed, open Privacy settings manually.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Text(viewModel.permissionDiagnostic)
                        .font(.caption)
                        .monospaced()
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    HStack {
                        Button {
                            viewModel.requestAccessibilityPermission()
                        } label: {
                            Label("Ask Permission", systemImage: "lock.open")
                        }

                        Button {
                            viewModel.openAccessibilitySettings()
                        } label: {
                            Label("Open Privacy", systemImage: "gear")
                        }

                        Button {
                            viewModel.quitApp()
                        } label: {
                            Label("Quit", systemImage: "power")
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("\(viewModel.selectedWindowIDs.count) selected")
            Spacer()
            Text(viewModel.statusMessage)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.footnote)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct WindowRow: View {
    let window: WindowSnapshot
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(window.appName)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(window.frame.width)) x \(Int(window.frame.height))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Text(window.title)
                        .font(.callout)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Text("x \(Int(window.frame.x)), y \(Int(window.frame.y))")
                        if let skipReason = window.skipReason {
                            Text(skipReason)
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!window.isAdjustable)
        .opacity(window.isAdjustable ? 1 : 0.55)
        .padding(.vertical, 4)
    }
}
