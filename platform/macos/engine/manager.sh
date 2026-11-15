#!/bin/bash
set -euo pipefail

ACTION="${1:-}"
ARG="${2:-}"

SOURCE="/Applications/Zalo.app"
BASE="$HOME/Applications/Zalo Accounts"
STATE="$HOME/Library/Application Support/ZaloLocalMulti"
LOGDIR="$HOME/Library/Logs"
LOG="$LOGDIR/ZaloLocalMulti.log"
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ICON_ROOT="$ENGINE_DIR/Icons"
STARTUP_FILE="$STATE/startup.conf"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/app.dalo.multi.startup.plist"
DOCK_PLIST="$HOME/Library/Preferences/com.apple.dock.plist"

mkdir -p "$BASE" "$STATE" "$LOGDIR"
: >> "$LOG"

log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }
fail(){ log "ERROR: $*"; printf 'ERROR: %s\n' "$*"; exit 1; }

plist_get(){
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}
set_string(){
  local plist="$1" key="$2" value="$3"
  if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist" >/dev/null
  else
    /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist" >/dev/null
  fi
}

get_idx(){
  local app="$1"
  local plist="$app/Contents/Info.plist"
  local idx bid
  idx="$(plist_get "$plist" "ZaloLocalMultiIndex")"
  if [[ -z "$idx" ]]; then
    bid="$(plist_get "$plist" "CFBundleIdentifier")"
    idx="$(printf '%s' "$bid" | sed -n 's/.*localclone\([0-9][0-9]*\)$/\1/p')"
  fi
  printf '%s' "$idx"
}

get_name(){
  local app="$1"
  local plist="$app/Contents/Info.plist"
  local n base
  n="$(plist_get "$plist" "ZaloLocalMultiDisplayName")"
  if [[ -z "$n" ]]; then
    base="$(basename "$app" .app)"
    n="${base#Zalo - }"
  fi
  printf '%s' "$n"
}

set_meta(){
  local app="$1" idx="$2" name="$3"
  local plist="$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Delete :ZaloLocalMultiIndex" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :ZaloLocalMultiIndex integer $idx" "$plist" >/dev/null
  /usr/libexec/PlistBuddy -c "Delete :ZaloLocalMultiDisplayName" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :ZaloLocalMultiDisplayName string $name" "$plist" >/dev/null
}

replace_fixed(){
  local file="$1" old="$2" new="$3" required="${4:-yes}"
  [[ ${#old} -eq ${#new} ]] || fail "Internal replacement length mismatch: '$old' vs '$new'"
  local offsets count=0
  offsets="$(LC_ALL=C grep -a -b -o -F "$old" "$file" 2>/dev/null | cut -d: -f1 || true)"
  if [[ -z "$offsets" ]]; then
    [[ "$required" == "yes" ]] && return 1 || return 0
  fi
  while IFS= read -r off; do
    [[ -n "$off" ]] || continue
    printf '%s' "$new" | dd of="$file" bs=1 seek="$off" conv=notrunc >>"$LOG" 2>&1
    count=$((count+1))
  done <<< "$offsets"
  log "PATCH '$old' -> '$new' count=$count file=$(basename "$file")"
}

kill_clone_path(){
  local app="$1"
  local pids
  pids="$(pgrep -f "$app/Contents/" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    log "Stopping clone processes before rebuild: $pids"
    while IFS= read -r p; do
      [[ -n "$p" ]] && kill "$p" 2>/dev/null || true
    done <<< "$pids"
    sleep 2
  fi
}

rename_helpers(){
  local app="$1" internal="$2" bid="$3"
  local fw="$app/Contents/Frameworks"
  local old helperbase suffix newbase newapp plist oldexe newexe role

  for old in "$fw"/Zalo\ Helper*.app; do
    [[ -d "$old" ]] || continue
    helperbase="$(basename "$old" .app)"
    suffix="${helperbase#Zalo}"
    newbase="${internal}${suffix}"
    newapp="$fw/$newbase.app"
    plist="$old/Contents/Info.plist"

    oldexe="$(plist_get "$plist" "CFBundleExecutable")"
    [[ -n "$oldexe" ]] || oldexe="$helperbase"
    newexe="$newbase"

    if [[ -f "$old/Contents/MacOS/$oldexe" ]]; then
      mv "$old/Contents/MacOS/$oldexe" "$old/Contents/MacOS/$newexe"
    elif [[ -f "$old/Contents/MacOS/$helperbase" ]]; then
      mv "$old/Contents/MacOS/$helperbase" "$old/Contents/MacOS/$newexe"
    else
      fail "Không tìm thấy helper executable trong $helperbase"
    fi

    set_string "$plist" "CFBundleExecutable" "$newexe"
    set_string "$plist" "CFBundleName" "$newbase"
    set_string "$plist" "CFBundleDisplayName" "$newbase"

    role="$(printf '%s' "$suffix" | tr ' ()' '___' | tr -cd 'A-Za-z0-9_')"
    set_string "$plist" "CFBundleIdentifier" "${bid}.helper${role}"

    mv "$old" "$newapp"
    log "HELPER $helperbase -> $newbase"
  done

  local c
  c="$(find "$fw" -maxdepth 1 -type d -name "${internal} Helper*.app" | wc -l | tr -d ' ')"
  [[ "$c" -ge 1 ]] || fail "Không rename được Electron helpers."
  log "Helper count for $internal = $c"
}

rebuild_clone(){
  local app="$1" idx="$2" name="$3"
  [[ -d "$SOURCE" ]] || fail "Không tìm thấy /Applications/Zalo.app"

  local saved_variant="blue"
  if [[ -d "$app" ]]; then
    saved_variant="$(plist_get "$app/Contents/Info.plist" "ZaloLocalMultiIconVariant")"
    [[ -n "$saved_variant" ]] || saved_variant="blue"
  fi

  kill_clone_path "$app"

  local tmp="$BASE/.rebuild-$idx-$$.app"
  rm -rf "$tmp"

  log "REBUILD v0.6 idx=$idx name=$name"
  if ! cp -c -R "$SOURCE" "$tmp" >>"$LOG" 2>&1; then
    ditto "$SOURCE" "$tmp" >>"$LOG" 2>&1 || fail "Không copy được Zalo gốc."
  fi

  local plist="$tmp/Contents/Info.plist"
  local asar="$tmp/Contents/Resources/app.asar"
  [[ -f "$asar" ]] || { rm -rf "$tmp"; fail "Không có app.asar."; }

  # Four-character internal product name. Same length as "Zalo", useful for
  # exact in-ASAR metadata patching and avoids Electron's shared app identity.
  local internal
  internal="$(printf 'Z%03d' "$idx")"
  local lower
  lower="$(printf '%s' "$internal" | tr '[:upper:]' '[:lower:]')"

  local bid="com.vng.zalo.localclone${idx}"
  local datafolder
  datafolder="$(printf 'ZLD%05d' "$idx")"   # exactly 8 chars, same as ZaloData
  local oldfolder
  oldfolder="$(printf 'ZLA%04d' "$idx")"    # exactly 7 chars, same as ZaloApp

  # Main bundle identity.
  set_string "$plist" "CFBundleIdentifier" "$bid"
  set_string "$plist" "CFBundleName" "$internal"
  set_string "$plist" "CFBundleDisplayName" "Zalo - $name"
  # Main executable stays "Zalo"; no shell wrapper, no fake HOME.
  set_string "$plist" "CFBundleExecutable" "Zalo"
  /usr/libexec/PlistBuddy -c "Delete :ElectronAsarIntegrity" "$plist" >/dev/null 2>&1 || true
  set_meta "$tmp" "$idx" "$name"

  # Rename all Electron helper bundles to match CFBundleName, otherwise Electron
  # aborts with "Unable to find helper app".
  rename_helpers "$tmp" "$internal" "$bid"

  # Zalo's own IPC sockets.
  local sn
  sn="$(printf '%04d' $((2000 + idx)))"
  replace_fixed "$asar" "/tmp/socketzalosend2021" "/tmp/socketzalosend${sn}" yes \
    || { rm -rf "$tmp"; fail "Không tìm thấy send socket."; }
  replace_fixed "$asar" "/tmp/socketzalorecv2021" "/tmp/socketzalorecv${sn}" yes \
    || { rm -rf "$tmp"; fail "Không tìm thấy recv socket."; }

  # Zalo application database folder — isolate without global symlinks.
  replace_fixed "$asar" "ZaloData" "$datafolder" no
  replace_fixed "$asar" "ZaloApp" "$oldfolder" no

  # Electron package identity. These replacements are exact-length and only
  # target JSON property patterns when present.
  replace_fixed "$asar" '"productName":"Zalo"' "\"productName\":\"$internal\"" no
  replace_fixed "$asar" '"productName": "Zalo"' "\"productName\": \"$internal\"" no
  replace_fixed "$asar" '"name":"zalo"' "\"name\":\"$lower\"" no
  replace_fixed "$asar" '"name": "zalo"' "\"name\": \"$lower\"" no

  # Preserve the Dalỏ icon selection across clone rebuild/update.
  if [[ -f "$ICON_ROOT/icns/$saved_variant.icns" ]]; then
    cp "$ICON_ROOT/icns/$saved_variant.icns" "$tmp/Contents/Resources/DaloClone.icns"
    set_string "$plist" "CFBundleIconFile" "DaloClone.icns"
    set_string "$plist" "ZaloLocalMultiIconVariant" "$saved_variant"
  fi

  # Ensure per-clone directories exist under the REAL macOS HOME.
  mkdir -p "$HOME/Library/Application Support/$datafolder"
  mkdir -p "$HOME/Library/Application Support/$internal"

  xattr -dr com.apple.quarantine "$tmp" >>"$LOG" 2>&1 || true
  codesign --force --deep --sign - "$tmp" >>"$LOG" 2>&1 \
    || { rm -rf "$tmp"; fail "codesign clone thất bại."; }

  # Atomic-ish swap with rollback. The old application bundle is kept until
  # the newly signed clone has moved into place successfully.
  local rollback="$BASE/.rollback-$idx-$$.app"
  rm -rf "$rollback"
  if [[ -d "$app" ]]; then
    mv "$app" "$rollback" || { rm -rf "$tmp"; fail "Không tạo được rollback bundle trước rebuild."; }
  fi

  if mv "$tmp" "$app"; then
    rm -rf "$rollback"
  else
    rm -rf "$app"
    [[ -d "$rollback" ]] && mv "$rollback" "$app" || true
    fail "Không thay được clone mới; Dalỏ đã thử khôi phục bundle cũ."
  fi

  local lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  [[ -x "$lsreg" ]] && "$lsreg" -f "$app" >/dev/null 2>&1 || true

  log "REBUILD SUCCESS app=$app internal=$internal datafolder=$datafolder bid=$bid"
}

repair_all(){
  local app idx name found=0
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    found=1
    idx="$(get_idx "$app")"
    [[ -n "$idx" ]] || idx=1
    name="$(get_name "$app")"
    rebuild_clone "$app" "$idx" "$name"
  done
  log "repair-all v0.6 found=$found"
  echo "OK"
}

allocate_idx(){
  local i=1 app
  while [[ $i -le 999 ]]; do
    local used=0
    for app in "$BASE"/Zalo\ -\ *.app; do
      [[ -d "$app" ]] || continue
      [[ "$(get_idx "$app")" == "$i" ]] && used=1
    done
    [[ $used -eq 0 ]] && { echo "$i"; return; }
    i=$((i+1))
  done
  return 1
}

create_clone(){
  local name="$1"
  [[ -n "$name" ]] || fail "Chưa nhập tên clone."
  local safe idx app
  safe="$(printf '%s' "$name" | tr '/:' '--' | tr '\t' ' ' | tr -d '\r\n')"
  app="$BASE/Zalo - $safe.app"
  [[ ! -e "$app" ]] || fail "Đã tồn tại clone '$safe'."
  idx="$(allocate_idx)" || fail "Không còn index."
  # Create placeholder metadata bundle by copying/rebuilding.
  cp -c -R "$SOURCE" "$app" 2>>"$LOG" || ditto "$SOURCE" "$app"
  set_meta "$app" "$idx" "$safe"
  rebuild_clone "$app" "$idx" "$safe"
  printf 'OK\t%s\n' "$idx"
}

list_clones(){
  local app base
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    base="$(basename "$app" .app)"
    printf '%s\n' "${base#Zalo - }"
  done
}

launch_clone(){
  local name="$1"
  local app="$BASE/Zalo - $name.app"
  [[ -d "$app" ]] || fail "Không tìm thấy clone '$name'."
  local idx internal
  idx="$(get_idx "$app")"
  internal="$(printf 'Z%03d' "$idx")"

  log "LAUNCH v0.6 clone name=$name idx=$idx internal=$internal"
  open -n "$app" || fail "open clone thất bại."
  sleep 3

  local p
  p="$(pgrep -f "$app/Contents/MacOS/Zalo" 2>/dev/null || true)"
  if [[ -n "$p" ]]; then
    log "LAUNCH SUCCESS clone pids=$p"
    log "Clone process detail:"
    ps ax -o pid=,command= | grep -F "$app/Contents/" | grep -v grep >> "$LOG" 2>&1 || true
    echo "OK"
  else
    log "LAUNCH FAILED clone has no process after 3 sec"
    echo "ERROR: Clone không còn process sau 3 giây."
    exit 1
  fi
}

launch_original(){
  log "LAUNCH ORIGINAL exact /Applications/Zalo.app"
  open -n "$SOURCE" || fail "Không mở được Zalo gốc."
  echo "OK"
}

diagnose(){
  echo "=== Original ==="
  echo "BundleID: $(plist_get "$SOURCE/Contents/Info.plist" CFBundleIdentifier)"
  echo "Name: $(plist_get "$SOURCE/Contents/Info.plist" CFBundleName)"
  echo
  local app idx internal datafolder
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    idx="$(get_idx "$app")"
    internal="$(printf 'Z%03d' "$idx")"
    datafolder="$(printf 'ZLD%05d' "$idx")"
    echo "=== $(basename "$app") ==="
    echo "Index: $idx"
    echo "BundleID: $(plist_get "$app/Contents/Info.plist" CFBundleIdentifier)"
    echo "CFBundleName: $(plist_get "$app/Contents/Info.plist" CFBundleName)"
    echo "Helpers:"
    find "$app/Contents/Frameworks" -maxdepth 1 -type d -name "$internal Helper*.app" -print | sed 's#.*/#  - #'
    echo "Data folder: $HOME/Library/Application Support/$datafolder"
    echo "Electron folder: $HOME/Library/Application Support/$internal"
    echo
  done
  echo "Processes:"
  ps ax -o pid=,command= | grep -E '/(Applications/Zalo.app|Zalo Accounts/)' | grep -v grep || true
}


find_app_by_idx(){
  local wanted="$1" app
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    if [[ "$(get_idx "$app")" == "$wanted" ]]; then
      printf '%s' "$app"
      return 0
    fi
  done
  return 1
}

is_clone_running(){
  local app="$1"
  pgrep -f "$app/Contents/" >/dev/null 2>&1
}

is_original_running(){
  pgrep -f "^/Applications/Zalo\.app/Contents/MacOS/Zalo( |$)" >/dev/null 2>&1
}

app_version(){
  local app="$1" v
  v="$(plist_get "$app/Contents/Info.plist" "CFBundleShortVersionString")"
  [[ -n "$v" ]] || v="$(plist_get "$app/Contents/Info.plist" "CFBundleVersion")"
  [[ -n "$v" ]] || v="?"
  printf '%s' "$v"
}

startup_contains(){
  local key="$1"
  [[ -f "$STARTUP_FILE" ]] || return 1
  grep -Fxq "$key" "$STARTUP_FILE" 2>/dev/null
}

dock_url_for_app(){
  local app="$1"
  printf 'file://%s/' "$app"
}

dock_contains(){
  local app="$1" wanted count i url
  [[ -f "$DOCK_PLIST" ]] || return 1
  wanted="$(dock_url_for_app "$app")"
  count="$(/usr/libexec/PlistBuddy -c 'Print :persistent-apps' "$DOCK_PLIST" 2>/dev/null | grep -c '^    Dict {' || true)"
  i=0
  while [[ "$i" -lt "$count" ]]; do
    url="$(/usr/libexec/PlistBuddy -c "Print :persistent-apps:$i:tile-data:file-data:_CFURLString" "$DOCK_PLIST" 2>/dev/null || true)"
    [[ "$url" == "$wanted" ]] && return 0
    i=$((i+1))
  done
  return 1
}

process_stats(){
  local app="$1" main_pattern="$2"
  local pids="" pid="" rss=0 elapsed="-" p r
  pids="$(pgrep -f "$app/Contents/" 2>/dev/null || true)"
  pid="$(pgrep -f "$main_pattern" 2>/dev/null | head -n 1 || true)"
  if [[ -n "$pids" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      r="$(ps -o rss= -p "$p" 2>/dev/null | tr -d ' ' || true)"
      [[ "$r" =~ ^[0-9]+$ ]] && rss=$((rss+r))
    done <<< "$pids"
  fi
  if [[ -n "$pid" ]]; then
    elapsed="$(ps -o etime= -p "$pid" 2>/dev/null | xargs || true)"
    [[ -n "$elapsed" ]] || elapsed="-"
  fi
  printf '%s\t%s\t%s' "${pid:-0}" "$rss" "$elapsed"
}

list_dashboard(){
  local app idx name status variant pid rss elapsed clonever sourcever needs startup docked stats
  sourcever="$(app_version "$SOURCE")"
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    idx="$(get_idx "$app")"
    name="$(get_name "$app")"
    if is_clone_running "$app"; then status="ON"; else status="OFF"; fi
    variant="$(plist_get "$app/Contents/Info.plist" "ZaloLocalMultiIconVariant")"
    [[ -n "$variant" ]] || variant="blue"
    stats="$(process_stats "$app" "$app/Contents/MacOS/Zalo")"
    pid="$(printf '%s' "$stats" | cut -f1)"
    rss="$(printf '%s' "$stats" | cut -f2)"
    elapsed="$(printf '%s' "$stats" | cut -f3)"
    clonever="$(app_version "$app")"
    if [[ "$clonever" != "$sourcever" ]]; then needs="YES"; else needs="NO"; fi
    if startup_contains "clone:$idx"; then startup="YES"; else startup="NO"; fi
    if dock_contains "$app"; then docked="YES"; else docked="NO"; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$idx" "$name" "$status" "$variant" "$pid" "$rss" "$elapsed" \
      "$clonever" "$sourcever" "$needs" "$startup" "$docked"
  done
}

original_dashboard(){
  local status stats pid rss elapsed version startup
  if is_original_running; then status="ON"; else status="OFF"; fi
  stats="$(process_stats "$SOURCE" "$SOURCE/Contents/MacOS/Zalo")"
  pid="$(printf '%s' "$stats" | cut -f1)"
  rss="$(printf '%s' "$stats" | cut -f2)"
  elapsed="$(printf '%s' "$stats" | cut -f3)"
  version="$(app_version "$SOURCE")"
  if startup_contains "original"; then startup="YES"; else startup="NO"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$status" "$pid" "$rss" "$elapsed" "$version" "$startup"
}

quit_clone(){
  local idx="$1" app pids p
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  pids="$(pgrep -f "$app/Contents/" 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    echo "OK"
    return 0
  fi
  log "QUIT clone idx=$idx pids=$pids"
  while IFS= read -r p; do
    [[ -n "$p" ]] && kill "$p" 2>/dev/null || true
  done <<< "$pids"
  sleep 2
  pids="$(pgrep -f "$app/Contents/" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && kill -9 "$p" 2>/dev/null || true
    done <<< "$pids"
  fi
  echo "OK"
}

quit_original(){
  local pids p
  pids="$(pgrep -f "^/Applications/Zalo\.app/Contents/" 2>/dev/null || true)"
  if [[ -z "$pids" ]]; then
    echo "OK"
    return 0
  fi
  log "QUIT original pids=$pids"
  while IFS= read -r p; do
    [[ -n "$p" ]] && kill "$p" 2>/dev/null || true
  done <<< "$pids"
  echo "OK"
}

rename_clone(){
  local idx="$1" newname="$2" app oldname safe newapp plist
  [[ -n "$newname" ]] || fail "Tên mới đang trống."
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  oldname="$(get_name "$app")"
  safe="$(printf '%s' "$newname" | tr '/:' '--' | tr '\t' ' ' | tr -d '\r\n')"
  [[ -n "$safe" ]] || fail "Tên mới không hợp lệ."
  newapp="$BASE/Zalo - $safe.app"

  if [[ "$newapp" != "$app" && -e "$newapp" ]]; then
    fail "Đã có clone tên '$safe'."
  fi

  quit_clone "$idx" >/dev/null || true
  plist="$app/Contents/Info.plist"

  set_string "$plist" "CFBundleDisplayName" "Zalo - $safe"
  /usr/libexec/PlistBuddy -c "Delete :ZaloLocalMultiDisplayName" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :ZaloLocalMultiDisplayName string $safe" "$plist" >/dev/null

  codesign --force --deep --sign - "$app" >>"$LOG" 2>&1 || fail "Không ký lại được clone."
  if [[ "$newapp" != "$app" ]]; then
    mv "$app" "$newapp"
  fi

  local lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  [[ -x "$lsreg" ]] && "$lsreg" -f "$newapp" >/dev/null 2>&1 || true
  log "RENAME clone idx=$idx '$oldname' -> '$safe'"
  echo "OK"
}

trash_path(){
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  local base target n=0
  base="$(basename "$path")"
  target="$HOME/.Trash/$base"
  while [[ -e "$target" ]]; do
    n=$((n+1))
    target="$HOME/.Trash/${base}-$n"
  done
  mv "$path" "$target"
  log "TRASH '$path' -> '$target'"
}

delete_clone(){
  local idx="$1" app internal datafolder olddata
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  quit_clone "$idx" >/dev/null || true

  internal="$(printf 'Z%03d' "$idx")"
  datafolder="$(printf 'ZLD%05d' "$idx")"
  olddata="$HOME/Library/Application Support/ZaloLocalMulti/Data/clone$idx"

  trash_path "$app"
  trash_path "$HOME/Library/Application Support/$internal"
  trash_path "$HOME/Library/Application Support/$datafolder"
  trash_path "$olddata"

  log "DELETE clone idx=$idx moved to Trash"
  echo "OK"
}

show_clone_app(){
  local idx="$1" app
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  open -R "$app"
  echo "OK"
}

open_clone_data(){
  local idx="$1" datafolder path
  datafolder="$(printf 'ZLD%05d' "$idx")"
  path="$HOME/Library/Application Support/$datafolder"
  mkdir -p "$path"
  open "$path"
  echo "OK"
}

open_logs(){
  mkdir -p "$LOGDIR"
  open "$LOGDIR"
  echo "OK"
}

settings_file="$STATE/settings.plist"

ensure_settings(){
  if [[ ! -f "$settings_file" ]]; then
    defaults write "$settings_file" ConfirmDelete -bool true
    defaults write "$settings_file" Notifications -bool true
    defaults write "$settings_file" OpenOriginalOnLaunch -bool false
  fi
}

setting_get(){
  local key="$1"
  ensure_settings
  defaults read "$settings_file" "$key" 2>/dev/null || echo "0"
}

setting_set(){
  local key="$1" value="$2"
  ensure_settings
  case "$key" in
    ConfirmDelete|Notifications|OpenOriginalOnLaunch)
      defaults write "$settings_file" "$key" -bool "$value"
      ;;
    *) fail "Setting không hợp lệ." ;;
  esac
  echo "OK"
}

status_original(){
  if is_original_running; then echo "ON"; else echo "OFF"; fi
}

repair_registration(){
  local lsreg app
  lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  if [[ -x "$lsreg" ]]; then
    "$lsreg" -f "$SOURCE" >/dev/null 2>&1 || true
    for app in "$BASE"/Zalo\ -\ *.app; do
      [[ -d "$app" ]] || continue
      "$lsreg" -f "$app" >/dev/null 2>&1 || true
    done
  fi
  echo "OK"
}


activate_clone(){
  local idx="$1" app
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  open "$app" || fail "Không thể đưa clone ra trước."
  echo "OK"
}

activate_original(){
  open "$SOURCE" || fail "Không thể đưa Zalo gốc ra trước."
  echo "OK"
}

clone_path(){
  local idx="$1" app
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  printf '%s\n' "$app"
}



xml_escape(){
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

refresh_launch_agent(){
  mkdir -p "$HOME/Library/LaunchAgents"
  local has=0
  if [[ -f "$STARTUP_FILE" ]] && grep -Eq '^(original|clone:[0-9]+)$' "$STARTUP_FILE"; then has=1; fi

  launchctl bootout "gui/$UID" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
  if [[ "$has" -eq 0 ]]; then
    rm -f "$LAUNCH_AGENT"
    return 0
  fi

  local helper
  helper="$(xml_escape "$ENGINE_DIR/manager.sh")"
  cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>app.dalo.multi.startup</string>
  <key>ProgramArguments</key>
  <array>
    <string>$helper</string>
    <string>startup-run</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>/tmp/dalo-multi-startup.log</string>
  <key>StandardErrorPath</key><string>/tmp/dalo-multi-startup.err</string>
</dict>
</plist>
EOF
  chmod 644 "$LAUNCH_AGENT"
  # Do not bootstrap immediately: enabling startup should affect the next macOS login,
  # not launch accounts right now. The LaunchAgent will be loaded automatically at login.
}

startup_set(){
  local key="$1" value="$2" tmp
  mkdir -p "$STATE"
  touch "$STARTUP_FILE"
  tmp="$STATE/startup.tmp.$$"
  grep -Fvx "$key" "$STARTUP_FILE" > "$tmp" 2>/dev/null || true
  if [[ "$value" == "1" || "$value" == "true" || "$value" == "YES" ]]; then
    printf '%s\n' "$key" >> "$tmp"
  fi
  sort -u "$tmp" > "$STARTUP_FILE"
  rm -f "$tmp"
  refresh_launch_agent
  echo "OK"
}

startup_run(){
  sleep 3
  if startup_contains "original"; then
    is_original_running || open -n "$SOURCE" >/dev/null 2>&1 || true
    sleep 1
  fi
  local line idx app name
  [[ -f "$STARTUP_FILE" ]] || exit 0
  while IFS= read -r line; do
    [[ "$line" =~ ^clone:([0-9]+)$ ]] || continue
    idx="${BASH_REMATCH[1]}"
    app="$(find_app_by_idx "$idx" 2>/dev/null || true)"
    [[ -d "$app" ]] || continue
    if ! is_clone_running "$app"; then
      name="$(get_name "$app")"
      launch_clone "$name" >/dev/null 2>&1 || true
      sleep 1
    fi
  done < "$STARTUP_FILE"
  echo "OK"
}

startup_agent_status(){
  if [[ -f "$LAUNCH_AGENT" ]]; then echo "ON"; else echo "OFF"; fi
}

repair_clone(){
  local idx="$1" app name
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  name="$(get_name "$app")"
  rebuild_clone "$app" "$idx" "$name"
  echo "OK"
}

update_stopped(){
  local app idx name src cv updated=0 skipped=0
  src="$(app_version "$SOURCE")"
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    cv="$(app_version "$app")"
    [[ "$cv" != "$src" ]] || continue
    if is_clone_running "$app"; then
      skipped=$((skipped+1))
      continue
    fi
    idx="$(get_idx "$app")"
    name="$(get_name "$app")"
    rebuild_clone "$app" "$idx" "$name"
    updated=$((updated+1))
  done
  printf 'UPDATED\t%s\tSKIPPED_RUNNING\t%s\n' "$updated" "$skipped"
}

health_dashboard(){
  local srcver app idx name bid expected internal helpers datafolder state msg cv sig
  if [[ ! -d "$SOURCE" ]]; then
    printf '0\tZalo gốc\tERROR\tKhông tìm thấy /Applications/Zalo.app\n'
    return 0
  fi
  srcver="$(app_version "$SOURCE")"
  printf '0\tZalo gốc\tOK\tPhiên bản %s · nguồn clone sẵn sàng\n' "$srcver"

  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    idx="$(get_idx "$app")"
    name="$(get_name "$app")"
    state="OK"
    msg="Sẵn sàng"
    expected="com.vng.zalo.localclone${idx}"
    bid="$(plist_get "$app/Contents/Info.plist" "CFBundleIdentifier")"
    internal="$(printf 'Z%03d' "$idx")"
    helpers="$(find "$app/Contents/Frameworks" -maxdepth 1 -type d -name "${internal} Helper*.app" 2>/dev/null | wc -l | tr -d ' ')"
    datafolder="$HOME/Library/Application Support/$(printf 'ZLD%05d' "$idx")"
    cv="$(app_version "$app")"

    if [[ "$bid" != "$expected" ]]; then
      state="ERROR"; msg="Bundle ID không đúng"
    elif [[ "$helpers" -lt 1 ]]; then
      state="ERROR"; msg="Thiếu Electron helper"
    elif [[ ! -d "$datafolder" ]]; then
      state="ERROR"; msg="Thiếu data folder riêng"
    elif ! codesign --verify --deep --strict "$app" >/dev/null 2>&1; then
      state="ERROR"; msg="Code signature không hợp lệ"
    elif [[ "$cv" != "$srcver" ]]; then
      state="WARN"; msg="Clone $cv · Zalo gốc $srcver · nên cập nhật"
    fi

    printf '%s\t%s\t%s\t%s\n' "$idx" "$name" "$state" "$msg"
  done
}

export_diagnostics(){
  local out srcver app idx bid internal datafolder cv helpers sig status stats pid rss elapsed
  out="$STATE/Dalo-Diagnostic-$(date '+%Y%m%d-%H%M%S').txt"
  srcver="$(app_version "$SOURCE")"
  {
    echo "Dalỏ Multi Diagnostic Report"
    echo "Generated: $(date '+%F %T %z')"
    echo
    echo "=== System ==="
    sw_vers 2>/dev/null || true
    echo "Architecture: $(uname -m)"
    echo
    echo "=== Zalo source ==="
    echo "Installed: $([[ -d "$SOURCE" ]] && echo YES || echo NO)"
    echo "Version: $srcver"
    echo "BundleID: $(plist_get "$SOURCE/Contents/Info.plist" CFBundleIdentifier)"
    echo
    echo "=== Clones (sanitized) ==="
    for app in "$BASE"/Zalo\ -\ *.app; do
      [[ -d "$app" ]] || continue
      idx="$(get_idx "$app")"
      bid="$(plist_get "$app/Contents/Info.plist" CFBundleIdentifier)"
      internal="$(printf 'Z%03d' "$idx")"
      datafolder="$HOME/Library/Application Support/$(printf 'ZLD%05d' "$idx")"
      cv="$(app_version "$app")"
      helpers="$(find "$app/Contents/Frameworks" -maxdepth 1 -type d -name "${internal} Helper*.app" 2>/dev/null | wc -l | tr -d ' ')"
      if codesign --verify --deep --strict "$app" >/dev/null 2>&1; then sig="OK"; else sig="FAIL"; fi
      if is_clone_running "$app"; then status="ON"; else status="OFF"; fi
      stats="$(process_stats "$app" "$app/Contents/MacOS/Zalo")"
      pid="$(printf '%s' "$stats" | cut -f1)"
      rss="$(printf '%s' "$stats" | cut -f2)"
      elapsed="$(printf '%s' "$stats" | cut -f3)"
      echo "Clone #$idx"
      echo "  Version: $cv"
      echo "  BundleID: $bid"
      echo "  InternalName: $internal"
      echo "  Helpers: $helpers"
      echo "  DataFolderExists: $([[ -d "$datafolder" ]] && echo YES || echo NO)"
      echo "  Signature: $sig"
      echo "  Running: $status"
      echo "  PID: $pid"
      echo "  RSS_KB: $rss"
      echo "  Uptime: $elapsed"
    done
    echo
    echo "=== Health ==="
    health_dashboard | sed -E 's/^([0-9]+)\t[^\t]*\t/\1\t[REDACTED]\t/'
  } > "$out"
  open -R "$out" >/dev/null 2>&1 || true
  printf '%s\n' "$out"
}

dock_backup(){
  [[ -f "$DOCK_PLIST" ]] || return 0
  mkdir -p "$STATE/Dock Backups"
  cp "$DOCK_PLIST" "$STATE/Dock Backups/com.apple.dock.$(date '+%Y%m%d-%H%M%S').plist" 2>/dev/null || true
}

dock_add(){
  local idx="$1" app count url
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  dock_contains "$app" && { echo "OK"; return 0; }
  [[ -f "$DOCK_PLIST" ]] || fail "Không tìm thấy Dock preferences."
  dock_backup
  count="$(/usr/libexec/PlistBuddy -c 'Print :persistent-apps' "$DOCK_PLIST" 2>/dev/null | grep -c '^    Dict {' || true)"
  url="$(dock_url_for_app "$app")"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count dict" "$DOCK_PLIST"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count:tile-data dict" "$DOCK_PLIST"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count:tile-data:file-data dict" "$DOCK_PLIST"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count:tile-data:file-data:_CFURLString string $url" "$DOCK_PLIST"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count:tile-data:file-data:_CFURLStringType integer 15" "$DOCK_PLIST"
  /usr/libexec/PlistBuddy -c "Add :persistent-apps:$count:tile-type string file-tile" "$DOCK_PLIST"
  killall Dock >/dev/null 2>&1 || true
  echo "OK"
}

dock_remove(){
  local idx="$1" app wanted count i url
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  [[ -f "$DOCK_PLIST" ]] || { echo "OK"; return 0; }
  dock_backup
  wanted="$(dock_url_for_app "$app")"
  count="$(/usr/libexec/PlistBuddy -c 'Print :persistent-apps' "$DOCK_PLIST" 2>/dev/null | grep -c '^    Dict {' || true)"
  i=$((count-1))
  while [[ "$i" -ge 0 ]]; do
    url="$(/usr/libexec/PlistBuddy -c "Print :persistent-apps:$i:tile-data:file-data:_CFURLString" "$DOCK_PLIST" 2>/dev/null || true)"
    if [[ "$url" == "$wanted" ]]; then
      /usr/libexec/PlistBuddy -c "Delete :persistent-apps:$i" "$DOCK_PLIST" >/dev/null
    fi
    i=$((i-1))
  done
  killall Dock >/dev/null 2>&1 || true
  echo "OK"
}

open_all(){
  local app name
  is_original_running || open -n "$SOURCE" >/dev/null 2>&1 || true
  sleep 1
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    is_clone_running "$app" && continue
    name="$(get_name "$app")"
    launch_clone "$name" >/dev/null 2>&1 || true
  done
  echo "OK"
}

quit_all_clones(){
  local app idx
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    idx="$(get_idx "$app")"
    quit_clone "$idx" >/dev/null 2>&1 || true
  done
  echo "OK"
}


window_screen_bounds(){
  local raw
  raw="$(osascript -e 'tell application "Finder" to get bounds of window of desktop' 2>/dev/null | tr -d ' ' || true)"
  [[ "$raw" =~ ^-?[0-9]+,-?[0-9]+,-?[0-9]+,-?[0-9]+$ ]] || fail "Không đọc được kích thước màn hình."
  printf '%s' "$raw"
}

window_set_geometry(){
  local pid="$1" x="$2" y="$3" w="$4" h="$5"
  osascript - "$pid" "$x" "$y" "$w" "$h" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  set targetPID to item 1 of argv as integer
  set px to item 2 of argv as integer
  set py to item 3 of argv as integer
  set pw to item 4 of argv as integer
  set ph to item 5 of argv as integer
  tell application "System Events"
    set targetProcess to first application process whose unix id is targetPID
    tell targetProcess
      if (count of windows) > 0 then
        set position of front window to {px, py}
        set size of front window to {pw, ph}
      end if
    end tell
  end tell
end run
APPLESCRIPT
}

window_get_geometry(){
  local pid="$1"
  osascript - "$pid" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set targetPID to item 1 of argv as integer
  tell application "System Events"
    set targetProcess to first application process whose unix id is targetPID
    tell targetProcess
      if (count of windows) is 0 then return ""
      set p to position of front window
      set s to size of front window
      return ((item 1 of p) as string) & "," & ((item 2 of p) as string) & "," & ((item 1 of s) as string) & "," & ((item 2 of s) as string)
    end tell
  end tell
end run
APPLESCRIPT
}

collect_running_windows(){
  local pid app idx stats
  if is_original_running; then
    pid="$(pgrep -f '^/Applications/Zalo\.app/Contents/MacOS/Zalo( |$)' | head -n 1 || true)"
    [[ -n "$pid" ]] && printf '0\t%s\n' "$pid"
  fi
  for app in "$BASE"/Zalo\ -\ *.app; do
    [[ -d "$app" ]] || continue
    is_clone_running "$app" || continue
    idx="$(get_idx "$app")"
    stats="$(process_stats "$app" "$app/Contents/MacOS/Zalo")"
    pid="$(printf '%s' "$stats" | cut -f1)"
    [[ "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]] && printf '%s\t%s\n' "$idx" "$pid"
  done
}

window_layout(){
  local mode="${1:-grid}" bounds left top right bottom sw sh data n cols rows i id pid col row x y w h offset
  data="$(collect_running_windows)"
  [[ -n "$data" ]] || fail "Chưa có cửa sổ Zalo nào đang chạy."
  n="$(printf '%s\n' "$data" | grep -c . | tr -d ' ')"

  bounds="$(window_screen_bounds)"
  IFS=',' read -r left top right bottom <<< "$bounds"
  sw=$((right-left)); sh=$((bottom-top))
  top=$((top+30)); sh=$((sh-85))

  case "$mode" in
    split)
      if [[ "$n" -le 2 ]]; then cols="$n"; else cols=2; fi
      rows=$(((n+cols-1)/cols))
      ;;
    grid)
      if [[ "$n" -le 1 ]]; then cols=1
      elif [[ "$n" -le 4 ]]; then cols=2
      elif [[ "$n" -le 9 ]]; then cols=3
      else cols=4
      fi
      rows=$(((n+cols-1)/cols))
      ;;
    cascade)
      cols=1; rows=1
      ;;
    *) fail "Layout không hợp lệ: $mode" ;;
  esac

  i=0
  while IFS=$'\t' read -r id pid; do
    [[ -n "$pid" ]] || continue
    if [[ "$mode" == "cascade" ]]; then
      w=$((sw*72/100)); h=$((sh*74/100)); offset=$((i*34))
      x=$((left+45+offset)); y=$((top+25+offset))
      if (( x+w > right )); then x=$((left+45)); fi
      if (( y+h > bottom )); then y=$((top+25)); fi
    else
      col=$((i%cols)); row=$((i/cols))
      w=$((sw/cols)); h=$((sh/rows))
      x=$((left+col*w)); y=$((top+row*h))
      x=$((x+6)); y=$((y+6)); w=$((w-12)); h=$((h-12))
    fi
    if ! window_set_geometry "$pid" "$x" "$y" "$w" "$h"; then
      fail "Không điều khiển được cửa sổ. Hãy cấp quyền Accessibility cho Dalỏ Multi rồi thử lại."
    fi
    i=$((i+1))
  done <<< "$data"
  echo "OK"
}

window_save(){
  local out="$STATE/window-layout.tsv" data id pid g
  data="$(collect_running_windows)"
  [[ -n "$data" ]] || fail "Chưa có cửa sổ Zalo nào để lưu."
  : > "$out"
  while IFS=$'\t' read -r id pid; do
    g="$(window_get_geometry "$pid" || true)"
    [[ -n "$g" ]] || continue
    printf '%s\t%s\n' "$id" "$g" >> "$out"
  done <<< "$data"
  [[ -s "$out" ]] || fail "Không đọc được vị trí cửa sổ. Hãy cấp quyền Accessibility cho Dalỏ Multi."
  echo "OK"
}

window_restore(){
  local in="$STATE/window-layout.tsv" id x y w h app stats pid
  [[ -s "$in" ]] || fail "Chưa có bố cục cửa sổ đã lưu."
  while IFS=$'\t,' read -r id x y w h; do
    [[ -n "$id" ]] || continue
    pid=""
    if [[ "$id" == "0" ]]; then
      pid="$(pgrep -f '^/Applications/Zalo\.app/Contents/MacOS/Zalo( |$)' | head -n 1 || true)"
    else
      app="$(find_app_by_idx "$id" 2>/dev/null || true)"
      [[ -d "$app" ]] || continue
      stats="$(process_stats "$app" "$app/Contents/MacOS/Zalo")"
      pid="$(printf '%s' "$stats" | cut -f1)"
    fi
    [[ "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]] || continue
    if ! window_set_geometry "$pid" "$x" "$y" "$w" "$h"; then
      fail "Không khôi phục được cửa sổ. Hãy cấp quyền Accessibility cho Dalỏ Multi."
    fi
  done < "$in"
  echo "OK"
}

apply_icon_internal(){
  local idx="$1" variant="$2" app plist src dst
  app="$(find_app_by_idx "$idx")" || fail "Không tìm thấy clone index $idx."
  plist="$app/Contents/Info.plist"
  src="$ICON_ROOT/icns/$variant.icns"
  [[ -f "$src" ]] || fail "Không tìm thấy icon variant '$variant'."

  if is_clone_running "$app"; then
    fail "Hãy tắt clone trước khi đổi icon để tránh ảnh hưởng process đang chạy."
  fi

  dst="$app/Contents/Resources/DaloClone.icns"
  cp "$src" "$dst"

  set_string "$plist" "CFBundleIconFile" "DaloClone.icns"
  if /usr/libexec/PlistBuddy -c "Print :ZaloLocalMultiIconVariant" "$plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Set :ZaloLocalMultiIconVariant $variant" "$plist" >/dev/null
  else
    /usr/libexec/PlistBuddy -c "Add :ZaloLocalMultiIconVariant string $variant" "$plist" >/dev/null
  fi

  xattr -dr com.apple.quarantine "$app" >>"$LOG" 2>&1 || true
  codesign --force --deep --sign - "$app" >>"$LOG" 2>&1 || fail "Không ký lại được clone sau khi đổi icon."

  local lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  [[ -x "$lsreg" ]] && "$lsreg" -f "$app" >/dev/null 2>&1 || true
  /usr/bin/touch "$app" 2>/dev/null || true

  log "ICON clone idx=$idx variant=$variant"
  echo "OK"
}

apply_icon(){
  apply_icon_internal "$1" "$2"
}

case "$ACTION" in
  create) create_clone "$ARG" ;;
  launch)
    # ARG can be an index (dashboard) or a legacy name.
    if [[ "$ARG" =~ ^[0-9]+$ ]]; then
      _app="$(find_app_by_idx "$ARG")" || fail "Không tìm thấy clone."
      _name="$(get_name "$_app")"
      launch_clone "$_name"
    else
      launch_clone "$ARG"
    fi
    ;;
  original) launch_original ;;
  activate-clone) activate_clone "$ARG" ;;
  activate-original) activate_original ;;
  clone-path) clone_path "$ARG" ;;
  list) list_clones ;;
  list-dashboard) list_dashboard ;;
  original-dashboard) original_dashboard ;;
  original-status) status_original ;;
  quit-clone) quit_clone "$ARG" ;;
  quit-original) quit_original ;;
  rename) rename_clone "$ARG" "${3:-}" ;;
  delete) delete_clone "$ARG" ;;
  show-app) show_clone_app "$ARG" ;;
  open-data) open_clone_data "$ARG" ;;
  open-logs) open_logs ;;
  apply-icon) apply_icon "$ARG" "${3:-blue}" ;;
  setting-get) setting_get "$ARG" ;;
  setting-set) setting_set "$ARG" "${3:-}" ;;
  repair-registration) repair_registration ;;
  repair-clone) repair_clone "$ARG" ;;
  repair-all) repair_all ;;
  update-stopped) update_stopped ;;
  health-dashboard) health_dashboard ;;
  export-diagnostics) export_diagnostics ;;
  startup-set) startup_set "$ARG" "${3:-0}" ;;
  startup-run) startup_run ;;
  startup-agent-status) startup_agent_status ;;
  dock-add) dock_add "$ARG" ;;
  dock-remove) dock_remove "$ARG" ;;
  open-all) open_all ;;
  quit-all-clones) quit_all_clones ;;
  window-layout) window_layout "$ARG" ;;
  window-save) window_save ;;
  window-restore) window_restore ;;
  diagnose) diagnose ;;
  *) fail "Action không hợp lệ: $ACTION" ;;
esac
