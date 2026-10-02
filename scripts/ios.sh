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

# Simulator.app lives inside whichever Xcode is installed. Try its bundle id,
# the Xcode that simctl comes from, xcode-select, /Applications, ~/Applications
# and Spotlight, then AppleScript.
open_simulator() {
  open -b com.apple.iphonesimulator >/dev/null 2>&1 && return 0
  local dev app
  dev="$(dirname "$(dirname "$(dirname "$(xcrun --find simctl 2>/dev/null || echo /x/x/x/x)")")")"
  for app in \
    "$dev/Applications/Simulator.app" \
    "$(xcode-select -p 2>/dev/null)/Applications/Simulator.app" \
    /Applications/Xcode*.app/Contents/Developer/Applications/Simulator.app \
    "$HOME"/Applications/Xcode*.app/Contents/Developer/Applications/Simulator.app \
    "$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.iphonesimulator'" 2>/dev/null | head -1 || true)"; do
    [ -n "$app" ] && [ -d "$app" ] && open "$app" && return 0
  done
  osascript -e 'tell application id "com.apple.iphonesimulator" to activate' >/dev/null 2>&1 && return 0
  say "Couldn't open the Simulator window by itself. Press ⌘-Space, type Simulator, press Enter — ONO will appear in it."
  return 0
}

# First connected, unlocked physical iPhone known to Flutter (empty if none).
connected_iphone() {
  flutter devices 2>/dev/null | grep -E '• ios ' | grep -vi 'simulator' | head -1 \
    | awk -F'•' '{gsub(/^ +| +$/, "", $2); print $2}' || true
}
