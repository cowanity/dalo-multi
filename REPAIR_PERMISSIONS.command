#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$ROOT/BUILD_ALL_DMG.command"
chmod +x "$ROOT/INSTALL_UNIVERSAL_LOCAL.command"
chmod +x "$ROOT/packaging/macos/build-dmgs.sh"
chmod +x "$ROOT/platform/macos/engine/manager.sh"
echo "✓ Đã sửa quyền chạy cho Dalỏ Multi Release Kit."
read -r -p "Nhấn Enter để đóng..."
