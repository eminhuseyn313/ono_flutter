#!/usr/bin/env bash
# Double-click to run ONO in the iPhone Simulator. Needs Xcode installed.
source "$(dirname "$0")/scripts/common.sh"

command -v xcrun >/dev/null 2>&1 || fail "Xcode isn't installed. Install it from the App Store, open it once, then run this again — or use 'Test in Chrome' instead."

# This app only targets iOS and web here, so skip the large Android
# downloads that `flutter upgrade` would otherwise fetch.
flutter config --no-enable-android >/dev/null 2>&1 || true

say "Updating Flutter so it supports the latest iOS simulators…"
echo "This downloads a few hundred MB once. On a slow connection it can take 10+ minutes."
echo "It is working as long as new lines keep appearing. Press Ctrl+C to cancel."
flutter upgrade || say "Flutter upgrade failed — continuing with the current version."
flutter pub get >/dev/null

say "Starting an iPhone simulator…"
DEVICE=$(xcrun simctl list devices booted | grep -m1 -E 'iPhone' | grep -oE '[0-9A-F-]{36}' || true)
if [ -z "$DEVICE" ]; then
  DEVICE=$(xcrun simctl list devices available | grep -E 'iPhone' | tail -1 | grep -oE '[0-9A-F-]{36}' || true)
  [ -n "$DEVICE" ] || fail "No iPhone simulator found. Open Xcode → Settings → Platforms and install an iOS simulator."
  xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
fi
# Simulator.app lives inside Xcode (Xcode.app, Xcode-beta.app, …), so open it
# by path rather than by name.
SIM_APP="$(xcode-select -p 2>/dev/null)/Applications/Simulator.app"
if [ ! -d "$SIM_APP" ]; then
  SIM_APP=$(ls -d /Applications/Xcode*.app/Contents/Developer/Applications/Simulator.app 2>/dev/null | head -1 || true)
fi
if [ -n "$SIM_APP" ] && [ -d "$SIM_APP" ]; then
  open "$SIM_APP"
else
  flutter emulators --launch apple_ios_simulator >/dev/null 2>&1 \
    || say "Couldn't open the Simulator window automatically — open Xcode, then Xcode menu → Open Developer Tool → Simulator."
fi

say "Building and launching ONO (first build takes a few minutes)…"
echo "Press q in this window to stop."
flutter run -d "$DEVICE" -t lib/main.dart \
  || fail "Simulator run failed. Use 'Test in Chrome' to test right away, and send me the error above."
