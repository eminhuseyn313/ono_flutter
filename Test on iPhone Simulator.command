#!/usr/bin/env bash
# Double-click to run ONO in the iPhone Simulator. Needs Xcode installed.
source "$(dirname "$0")/scripts/common.sh"

command -v xcrun >/dev/null 2>&1 || fail "Xcode isn't installed. Install it from the App Store, open it once, then run this again — or use 'Test in Chrome' instead."

say "Updating Flutter so it supports the latest iOS simulators (can take a few minutes)…"
flutter upgrade || say "Flutter upgrade failed — continuing with the current version."
flutter pub get >/dev/null

say "Starting an iPhone simulator…"
DEVICE=$(xcrun simctl list devices booted | grep -m1 -E 'iPhone' | grep -oE '[0-9A-F-]{36}' || true)
if [ -z "$DEVICE" ]; then
  DEVICE=$(xcrun simctl list devices available | grep -E 'iPhone' | tail -1 | grep -oE '[0-9A-F-]{36}' || true)
  [ -n "$DEVICE" ] || fail "No iPhone simulator found. Open Xcode → Settings → Platforms and install an iOS simulator."
  xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
fi
open -a Simulator

say "Building and launching ONO (first build takes a few minutes)…"
echo "Press q in this window to stop."
flutter run -d "$DEVICE" -t lib/main.dart \
  || fail "Simulator run failed. Use 'Test in Chrome' to test right away, and send me the error above."
