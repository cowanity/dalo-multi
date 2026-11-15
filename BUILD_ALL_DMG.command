#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
echo "Dalỏ Multi v1.3 — build 3 macOS DMG"
echo "Apple Silicon + Intel + Universal"
echo
"$ROOT/packaging/macos/build-dmgs.sh"
echo
read -r -p "Hoàn tất. Nhấn Enter để đóng..."
