#!/usr/bin/env bash
# Shared helpers for the iOS launchers. Sourced after scripts/common.sh.

need_xcode() {
  command -v xcrun >/dev/null 2>&1 \
    || fail "Xcode isn't installed. Install it from the App Store, open it once, then run this again."
  local dev
  dev="$(xcode-select -p 2>/dev/null || true)"
  case "$dev" in
    *CommandLineTools*|"")
      fail "Your Mac is set to the Command Line Tools instead of Xcode. In Terminal run:
  sudo xcode-select -s /Applications/Xcode.app
(use the name of your Xcode app if it differs), then run this again." ;;
  esac
  echo "Using Xcode at: ${dev%/Contents/Developer}"
  # This app only targets iOS and web here; skip Android tooling entirely.
  flutter config --no-enable-android >/dev/null 2>&1 || true
}

# Upgrade Flutter at most every 14 days — it is slow and was the step that
# used to hang. Force it with ONO_UPGRADE=1.
maybe_upgrade_flutter() {
  local stamp="$HOME/.ono_flutter_upgraded"
  if [ "${ONO_UPGRADE:-0}" = 1 ] || [ ! -f "$stamp" ] || [ -n "$(find "$stamp" -mtime +14 2>/dev/null)" ]; then
    say "Updating Flutter (every two weeks; can take several minutes)…"
    if flutter upgrade; then touch "$stamp"; else say "Flutter upgrade failed — continuing with the current version."; fi
    flutter pub get >/dev/null
  fi
}

booted_iphone() {
  xcrun simctl list devices booted 2>/dev/null | grep -m1 -E 'iPhone' | grep -oE '[0-9A-F-]{36}' || true
}

# Show the simulated iPhone [udid] on screen.
# Xcode 27+: Simulator.app is gone; Device Hub (DeviceHub.app, bundle id
# com.apple.dt.Devices, in Xcode.app/Contents/Applications) replaces it and
# opens a device via devices://device/open?id=<udid>.
# Xcode 26 and older: Simulator.app (com.apple.iphonesimulator).
open_simulator() {
  local udid="${1:-}" xcode app err tried=""
  xcode="$(xcode-select -p 2>/dev/null)"; xcode="${xcode%/Contents/Developer}"
  try() { tried="$tried\n  $*"; err=$("$@" 2>&1) && return 0; tried="$tried → ${err:-failed}"; return 1; }

  if [ -n "$udid" ]; then try open "devices://device/open?id=$udid" && return 0; fi
  try open -b com.apple.dt.Devices && return 0
  for app in "$xcode/Contents/Applications/DeviceHub.app" /Applications/Xcode*.app/Contents/Applications/DeviceHub.app; do
    [ -d "$app" ] && try open "$app" && return 0
  done
  try open -b com.apple.iphonesimulator && return 0
  for app in "$xcode/Contents/Developer/Applications/Simulator.app" /Applications/Xcode*.app/Contents/Developer/Applications/Simulator.app; do
    [ -d "$app" ] && try open "$app" && return 0
  done
  say "Couldn't open Device Hub / Simulator. ONO still runs on the simulated iPhone."
  printf "Tried:%b\n" "$tried"
  echo "Open it by hand: Xcode → Window → Device Hub (or Open Developer Tool → Simulator)."
  return 0
}

# First connected, unlocked physical iPhone known to Flutter (empty if none).
connected_iphone() {
  flutter devices 2>/dev/null | grep -E '• ios ' | grep -vi 'simulator' | head -1 \
    | awk -F'•' '{gsub(/^ +| +$/, "", $2); print $2}' || true
}

# Ask once whether to turn on the extras that depend on the Apple account.
ask_capabilities_once() {
  [ -f ios/.capabilities/.asked ] && return 0
  mkdir -p ios/.capabilities
  echo
  echo "Two optional extras need your Apple account to support them."
  echo "Say n if unsure — you can turn them on later with scripts/capabilities.sh."
  local a b
  read -r -p "  Apple Health (sleep, HRV, weigh-ins)? [y/N] " a
  read -r -p "  Home Screen & Lock Screen widget? [y/N] " b
  [[ "$a" =~ ^[Yy] ]] && touch ios/.capabilities/health
  [[ "$b" =~ ^[Yy] ]] && touch ios/.capabilities/widget
  touch ios/.capabilities/.asked
  bash scripts/capabilities.sh apply || say "Couldn't add them — continuing without."
}
