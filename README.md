# MacAlignmentPlugin

MacAlignmentPlugin is a small macOS utility for saving, resizing, and restoring window layouts on the current desktop or current Stage Manager workspace.

It is built for workflows where you want several apps, such as Terminal, Finder, ChatGPT, WeChat, Codex, or a browser, to return to known positions and sizes without manually arranging them every time.

## Features

- Menu bar utility with a movable floating control window.
- Custom Launchpad and Dock app icon.
- Lists adjustable macOS windows from the current workspace.
- Supports manual per-window selection.
- Saves selected window positions and sizes as reusable layout presets.
- Applies saved layouts to selected windows.
- Supports quick resizing with built-in presets or custom width and height.
- Keeps the window's top-left position when resizing.
- Clamps oversized windows to the visible screen area.
- Skips full-screen, minimized, system-only, and non-adjustable windows.
- Uses public macOS APIs only: Accessibility and CoreGraphics window listing.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools
- Swift 6 compatible toolchain
- Accessibility permission for `MacAlignmentPlugin`

Check Swift:

```bash
swift --version
```

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/MacAlignmentPlugin.git
cd MacAlignmentPlugin
```

Build and install the app to `/Applications`:

```bash
./Scripts/install_app.sh
```

Launch it:

```bash
open /Applications/MacAlignmentPlugin.app
```

For normal use, launch the installed app from `/Applications`. Avoid running with `swift run`, because macOS Accessibility permissions are more reliable for a real `.app` bundle.

## Accessibility Permission

macOS requires Accessibility permission before one app can read or resize another app's windows.

1. Open `MacAlignmentPlugin`.
2. Click `Ask Permission`.
3. In the macOS permission dialog, choose `Open System Settings`.
4. In `System Settings -> Privacy & Security -> Accessibility`, enable `MacAlignmentPlugin`.
5. Quit and reopen the app:

```bash
pkill -x MacAlignmentPlugin
open /Applications/MacAlignmentPlugin.app
```

The app shows a diagnostic line while permission is missing. It should show `Trust: true` after Accessibility permission is active.

If permission gets stuck:

```bash
tccutil reset Accessibility local.macalignment.plugin
pkill -x MacAlignmentPlugin
open /Applications/MacAlignmentPlugin.app
```

Then enable `MacAlignmentPlugin` again in Accessibility settings.

## Usage

### Save a Layout

1. Arrange your windows manually.
2. Open MacAlignmentPlugin from the menu bar.
3. Select the windows you want to capture.
4. Enter a layout name.
5. Click `Save`.

The layout records each selected window's app, title hint, position, and size.

### Apply a Layout

1. Open the windows you want to manage.
2. Open MacAlignmentPlugin.
3. Select the target windows.
4. Choose a saved layout from `Saved`.
5. Click `Apply`.

The app matches selected windows by bundle identifier and title where possible.

### Quick Resize

1. Select one or more windows.
2. Choose a preset size, or enter a custom width and height.
3. Click `Apply Preset` or `Apply Custom Size`.

Quick Resize keeps each window's top-left point fixed. If the requested size would extend beyond the visible screen area, the app uses the largest size that fits.

## Stage Manager Notes

The reliable scope is the current desktop and the currently active Stage Manager workspace.

Stage Manager side thumbnails are best-effort. macOS may expose some inactive windows through Accessibility, but some thumbnails are only visual previews and cannot be resized as real windows.

## Development

Build a development `.app` bundle:

```bash
./Scripts/build_app.sh
open .build/MacAlignmentPlugin.app
```

Install the app to `/Applications`:

```bash
./Scripts/install_app.sh
open /Applications/MacAlignmentPlugin.app
```

Restart the installed app:

```bash
./Scripts/restart_app.sh
```

Development builds are ad-hoc signed unless you configure a signing identity. Rebuilding can invalidate Accessibility approval, so after rebuilding you may need to toggle the permission off and on again.

## Troubleshooting

### The app says `Trust: false`

Accessibility permission is not active for the currently running app.

- Make sure you launched `/Applications/MacAlignmentPlugin.app`.
- Turn `MacAlignmentPlugin` off and on again in Accessibility settings.
- Quit and reopen the app.
- If needed, run `tccutil reset Accessibility local.macalignment.plugin`.

### A window does not appear

Some windows are not exposed by macOS as adjustable Accessibility windows. This often includes full-screen windows, minimized windows, Stage Manager thumbnails, desktop/root Finder windows, and some system surfaces.

### A full-screen app appears from another desktop

The app filters common title-bar fragments and desktop/root windows, but macOS can still expose unusual system window records. Refresh after switching to the workspace you want to manage.

### Finder shows an extra `Untitled` window

Finder can expose the desktop/root window as an Accessibility window. MacAlignmentPlugin filters the common full-desktop `Untitled` Finder window.

## Limitations

- The app does not use private macOS APIs.
- It cannot reliably enumerate or control every Space/Desktop by number.
- It cannot resize full-screen windows.
- It cannot guarantee control over inactive Stage Manager thumbnail groups.
- Apps can refuse or partially ignore Accessibility resize requests.

## License

MacAlignmentPlugin is released under the MIT License. See [LICENSE](LICENSE).
