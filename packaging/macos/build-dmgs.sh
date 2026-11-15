#!/bin/bash
set -euo pipefail

# Dalỏ Multi macOS release builder
# Produces:
#   arm64     -> Apple Silicon
#   x86_64    -> Intel
#   universal -> arm64 + x86_64
#
# No third-party packaging dependency: only Xcode/CLT + macOS native tools.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${VERSION:-1.3.0}"
BUILD_NUMBER="${BUILD_NUMBER:-130}"
RELEASE_LABEL="${RELEASE_LABEL:-v1.3}"
MIN_MACOS="${MIN_MACOS:-14.0}"
BUNDLE_ID="${BUNDLE_ID:-app.dalo.multi}"

SRC="$ROOT/apps/macos/Sources/DaloMultiApp.swift"
ENGINE="$ROOT/platform/macos/engine/manager.sh"
PNG_DIR="$ROOT/shared/assets/icons/png"
ICNS_DIR="$ROOT/shared/assets/icons/icns"
PLIST_TEMPLATE="$ROOT/packaging/macos/Info.plist.in"

BUILD="$ROOT/.build/macos-release"
DIST="$ROOT/dist"
APP_NAME="Dalo Multi.app"
EXECUTABLE="DaloMulti"

SIGN_IDENTITY="${MACOS_SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

# If Terminal itself is under Rosetta on Apple Silicon, re-run the builder natively.
HW_ARM64="$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)"
if [[ "$HW_ARM64" == "1" && "$(uname -m)" != "arm64" && "${DALO_NATIVE_REEXEC:-0}" != "1" ]]; then
  echo "↻ Terminal đang chạy qua Rosetta; chuyển release builder sang arm64 native..."
  exec env DALO_NATIVE_REEXEC=1 arch -arm64 "$0" "$@"
fi

say() { printf '\033[1;34m%s\033[0m\n' "$*"; }
ok()  { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m⚠ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "Thiếu command: $1"
}

preflight() {
  [[ "$(uname -s)" == "Darwin" ]] || die "Script này phải chạy trên macOS."
  [[ -f "$SRC" ]] || die "Thiếu Swift source: $SRC"
  [[ -f "$ENGINE" ]] || die "Thiếu engine: $ENGINE"
  chmod +x "$ENGINE" 2>/dev/null || die "Không thể cấp quyền chạy cho engine: $ENGINE"
  # Self-heal the main app icon alias from the approved blue icon if needed.
  if [[ ! -s "$PNG_DIR/dalo_main.png" && -s "$PNG_DIR/blue.png" ]]; then
    cp "$PNG_DIR/blue.png" "$PNG_DIR/dalo_main.png"
  fi
  if [[ ! -s "$ICNS_DIR/dalo_main.icns" && -s "$ICNS_DIR/blue.icns" ]]; then
    cp "$ICNS_DIR/blue.icns" "$ICNS_DIR/dalo_main.icns"
  fi
  [[ -s "$PNG_DIR/dalo_main.png" ]] || die "Thiếu Dalỏ main PNG."
  [[ -s "$ICNS_DIR/dalo_main.icns" ]] || die "Thiếu Dalỏ main ICNS."

  require xcrun
  require lipo
  require codesign
  require hdiutil
  require shasum
  require ditto

  xcrun --find swiftc >/dev/null 2>&1 || die "Không tìm thấy swiftc. Cài Xcode hoặc Xcode Command Line Tools."
  SDK="$(xcrun --sdk macosx --show-sdk-path)"
  export SDK

  say "Dalỏ Multi macOS Release Builder"
  echo "  Release     : $RELEASE_LABEL"
  echo "  App version : $VERSION ($BUILD_NUMBER)"
  echo "  Minimum OS  : macOS $MIN_MACOS"
  echo "  Host        : $(uname -m)"
  echo "  SDK         : $SDK"

  if [[ -n "$SIGN_IDENTITY" ]]; then
    ok "Developer signing: $SIGN_IDENTITY"
  else
    warn "Không có MACOS_SIGN_IDENTITY → build sẽ dùng ad-hoc signing."
    warn "DMG vẫn dùng cá nhân/test được, nhưng public GitHub nên Developer ID + notarization."
  fi

  if [[ -n "$NOTARY_PROFILE" && -z "$SIGN_IDENTITY" ]]; then
    die "Có NOTARY_PROFILE nhưng chưa có MACOS_SIGN_IDENTITY."
  fi
}

reset_output() {
  rm -rf "$BUILD"
  mkdir -p "$BUILD/bin" "$BUILD/apps" "$BUILD/dsym" "$BUILD/dmg" "$DIST"
}

compile_thin() {
  local arch="$1"
  local out="$BUILD/bin/$arch/$EXECUTABLE"
  mkdir -p "$(dirname "$out")"

  say "Compile $arch..."
  xcrun swiftc \
    -parse-as-library \
    -O \
    -whole-module-optimization \
    -g \
    -target "${arch}-apple-macos${MIN_MACOS}" \
    -sdk "$SDK" \
    -framework SwiftUI \
    -framework AppKit \
    "$SRC" \
    -o "$out"

  [[ -x "$out" ]] || die "Không tạo được binary $arch."

  local actual
  actual="$(lipo -archs "$out")"
  [[ "$actual" == *"$arch"* ]] || die "Binary $arch sai kiến trúc: $actual"

  xcrun dsymutil "$out" -o "$BUILD/dsym/DaloMulti-$arch.dSYM" >/dev/null 2>&1 || true
  strip -x "$out" 2>/dev/null || true
  ok "Binary $arch: $(lipo -archs "$out")"
}

make_universal_binary() {
  local arm="$BUILD/bin/arm64/$EXECUTABLE"
  local intel="$BUILD/bin/x86_64/$EXECUTABLE"
  local out="$BUILD/bin/universal/$EXECUTABLE"
  mkdir -p "$(dirname "$out")"

  say "Ghép Universal binary..."
  lipo -create "$arm" "$intel" -output "$out"

  local actual
  actual="$(lipo -archs "$out")"
  [[ "$actual" == *"arm64"* && "$actual" == *"x86_64"* ]] || die "Universal binary không đủ 2 slice: $actual"

  xcrun dsymutil "$out" -o "$BUILD/dsym/DaloMulti-universal.dSYM" >/dev/null 2>&1 || true
  strip -x "$out" 2>/dev/null || true
  ok "Universal: $actual"
}

render_plist() {
  local variant="$1"
  local dest="$2"
  sed \
    -e "s|__BUNDLE_ID__|$BUNDLE_ID|g" \
    -e "s|__VERSION__|$VERSION|g" \
    -e "s|__BUILD_NUMBER__|$BUILD_NUMBER|g" \
    -e "s|__MIN_MACOS__|$MIN_MACOS|g" \
    -e "s|__VARIANT__|$variant|g" \
    "$PLIST_TEMPLATE" > "$dest"
}

sign_app() {
  local app="$1"
  if [[ -n "$SIGN_IDENTITY" ]]; then
    codesign \
      --force \
      --options runtime \
      --timestamp \
      --sign "$SIGN_IDENTITY" \
      "$app"
  else
    codesign --force --sign - "$app"
  fi
  codesign --verify --deep --strict --verbose=2 "$app"
}

package_app() {
  local variant="$1"
  local binary="$BUILD/bin/$variant/$EXECUTABLE"
  local appdir="$BUILD/apps/$variant/$APP_NAME"

  say "Package app: $variant..."
  rm -rf "$appdir"
  mkdir -p \
    "$appdir/Contents/MacOS" \
    "$appdir/Contents/Resources/Icons/png" \
    "$appdir/Contents/Resources/Icons/icns"

  cp "$binary" "$appdir/Contents/MacOS/$EXECUTABLE"
  chmod +x "$appdir/Contents/MacOS/$EXECUTABLE"

  cp "$ENGINE" "$appdir/Contents/Resources/manager.sh"
  chmod +x "$appdir/Contents/Resources/manager.sh"

  cp "$PNG_DIR"/*.png "$appdir/Contents/Resources/Icons/png/"
  cp "$ICNS_DIR"/*.icns "$appdir/Contents/Resources/Icons/icns/"
  cp "$ICNS_DIR/dalo_main.icns" "$appdir/Contents/Resources/DaloMulti.icns"

  render_plist "$variant" "$appdir/Contents/Info.plist"

  xattr -dr com.apple.quarantine "$appdir" 2>/dev/null || true
  sign_app "$appdir"

  local actual
  actual="$(lipo -archs "$appdir/Contents/MacOS/$EXECUTABLE")"
  case "$variant" in
    arm64) [[ "$actual" == "arm64" ]] || die "App arm64 sai slice: $actual" ;;
    x86_64) [[ "$actual" == "x86_64" ]] || die "App Intel sai slice: $actual" ;;
    universal)
      [[ "$actual" == *"arm64"* && "$actual" == *"x86_64"* ]] || die "App Universal sai slice: $actual"
      ;;
  esac

  ok "$variant app verified: $actual"
}

variant_label() {
  case "$1" in
    arm64) echo "AppleSilicon" ;;
    x86_64) echo "Intel" ;;
    universal) echo "Universal" ;;
    *) echo "$1" ;;
  esac
}

notarize_dmg_if_configured() {
  local dmg="$1"
  if [[ -z "$NOTARY_PROFILE" ]]; then
    return 0
  fi

  say "Notarize $(basename "$dmg")..."
  xcrun notarytool submit "$dmg" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
  ok "Notarized: $(basename "$dmg")"
}

make_dmg() {
  local variant="$1"
  local label
  label="$(variant_label "$variant")"

  local appdir="$BUILD/apps/$variant/$APP_NAME"
  local stage="$BUILD/dmg/stage-$variant"
  local dmg="$DIST/Dalo-Multi-${RELEASE_LABEL}-macOS-${label}.dmg"

  rm -rf "$stage" "$dmg"
  mkdir -p "$stage"

  ditto "$appdir" "$stage/$APP_NAME"
  ln -s /Applications "$stage/Applications"

  say "Create DMG: $(basename "$dmg")..."
  hdiutil create \
    -volname "Dalỏ Multi" \
    -srcfolder "$stage" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$dmg" >/dev/null

  hdiutil verify "$dmg" >/dev/null

  if [[ -n "$SIGN_IDENTITY" ]]; then
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$dmg"
    codesign --verify --verbose=2 "$dmg"
  fi

  notarize_dmg_if_configured "$dmg"
  ok "DMG ready: $dmg"
}

make_checksums() {
  say "Generate SHA-256..."
  (
    cd "$DIST"
    shasum -a 256 Dalo-Multi-"$RELEASE_LABEL"-macOS-*.dmg > SHA256SUMS.txt
  )

  cat > "$DIST/release-manifest.json" <<EOF
{
  "product": "Dalỏ Multi",
  "version": "$VERSION",
  "build": "$BUILD_NUMBER",
  "minimum_macos": "$MIN_MACOS",
  "artifacts": [
    "Dalo-Multi-${RELEASE_LABEL}-macOS-AppleSilicon.dmg",
    "Dalo-Multi-${RELEASE_LABEL}-macOS-Intel.dmg",
    "Dalo-Multi-${RELEASE_LABEL}-macOS-Universal.dmg"
  ],
  "signing": "$( [[ -n "$SIGN_IDENTITY" ]] && echo developer_id || echo adhoc )",
  "notarized": "$( [[ -n "$NOTARY_PROFILE" ]] && echo true || echo false )"
}
EOF

  ok "Checksums: $DIST/SHA256SUMS.txt"
}

summary() {
  echo
  say "Release complete"
  echo
  ls -lh "$DIST"/Dalo-Multi-"$RELEASE_LABEL"-macOS-*.dmg
  echo
  echo "Architectures:"
  echo "  Apple Silicon : $(lipo -archs "$BUILD/apps/arm64/$APP_NAME/Contents/MacOS/$EXECUTABLE")"
  echo "  Intel         : $(lipo -archs "$BUILD/apps/x86_64/$APP_NAME/Contents/MacOS/$EXECUTABLE")"
  echo "  Universal     : $(lipo -archs "$BUILD/apps/universal/$APP_NAME/Contents/MacOS/$EXECUTABLE")"
  echo
  if [[ -z "$SIGN_IDENTITY" ]]; then
    warn "Đây là ad-hoc build. Dùng cá nhân/test ổn; trước khi public GitHub hãy ký Developer ID + notarize."
  else
    ok "Developer ID signed."
  fi
}

main() {
  preflight
  reset_output
  compile_thin arm64
  compile_thin x86_64
  make_universal_binary

  package_app arm64
  package_app x86_64
  package_app universal

  make_dmg arm64
  make_dmg x86_64
  make_dmg universal

  make_checksums
  summary
}

main "$@"
