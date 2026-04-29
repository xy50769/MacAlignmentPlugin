#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/MacAlignmentPlugin.app"

pkill -x MacAlignmentPlugin 2>/dev/null || true
sleep 0.5
open "$APP_DIR"
