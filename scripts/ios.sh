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
# A paid Apple Developer Program team supports all of them; a free Apple
# ID doesn't. Asked again once for people who said no before joining, and
# the watch app once more on its own (another target to build, so it can
# be left out without losing the rest).
ask_capabilities_once() {
  local asked=0 a w
  mkdir -p ios/.capabilities
  if [ ! -f ios/.capabilities/.asked-paid ]; then
    asked=1
    echo
    echo "Is your Apple ID in the paid Apple Developer Program (\$99/year)?"
    echo "With it ONO gets Apple Health, the Home & Lock Screen widgets, the"
    echo "Lock Screen timer and Sign in with Apple. A free Apple ID can't sign them."
    read -r -p "  Paid Apple Developer Program? [Y/n] " a
    if [[ ! "$a" =~ ^[Nn] ]]; then
      touch ios/.capabilities/health ios/.capabilities/widget ios/.capabilities/apple
    fi
    touch ios/.capabilities/.asked ios/.capabilities/.asked-paid
  fi
  if [ ! -f ios/.capabilities/.asked-watch ] && [ -f ios/.capabilities/widget ]; then
    asked=1
    read -r -p "  Apple Watch app (tick today's list, timers on the wrist)? [Y/n] " w
    [[ ! "$w" =~ ^[Nn] ]] && touch ios/.capabilities/watch
    touch ios/.capabilities/.asked-watch
  fi
  [ "$asked" = 1 ] || return 0
  bash scripts/capabilities.sh apply || say "Couldn't add them — continuing without."
}
