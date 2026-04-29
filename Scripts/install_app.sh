#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$ROOT_DIR/.build/MacAlignmentPlugin.app"
TARGET_APP="/Applications/MacAlignmentPlugin.app"

"$ROOT_DIR/Scripts/build_app.sh"

pkill -x MacAlignmentPlugin 2>/dev/null || true
rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"
codesign --force --deep --sign - "$TARGET_APP" >/dev/null

echo "$TARGET_APP"
