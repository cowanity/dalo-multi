#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
APP_BUILD="$ROOT/.build/macos-release/apps/universal/Dalo Multi.app"

if [[ ! -d "$APP_BUILD" ]]; then
  echo "Chưa có Universal app. Đang build toàn bộ release trước..."
  "$ROOT/packaging/macos/build-dmgs.sh"
fi

TARGET="$HOME/Applications/Dalo Multi.app"
mkdir -p "$HOME/Applications"
rm -rf "$TARGET"
ditto "$APP_BUILD" "$TARGET"
open "$TARGET"
echo "Đã cài: $TARGET"
