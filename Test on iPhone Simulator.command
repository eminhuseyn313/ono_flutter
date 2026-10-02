#!/usr/bin/env bash
# Double-click to run ONO in the iPhone Simulator. Needs Xcode installed.
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter

say "Starting a simulated iPhone…"
DEVICE=$(booted_iphone)
if [ -z "$DEVICE" ]; then
  # Newest iPhone runtime, last listed model (e.g. iPhone 17 Pro).
  DEVICE=$(xcrun simctl list devices available | grep -E '^\s+iPhone' | tail -1 | grep -oE '[0-9A-F-]{36}' || true)
  [ -n "$DEVICE" ] || fail "No simulated iPhone is installed. Xcode → Settings → Components: install iOS, then run this again."
  xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || true
fi
open_simulator "$DEVICE"
echo "Simulator: $(xcrun simctl list devices | grep "$DEVICE" | sed -E 's/ \(.*//; s/^ +//')"

say "Building and launching ONO (first build takes a few minutes)…"
echo "ONO appears on the simulated iPhone (Device Hub). Leave this window open; press q here to stop."
flutter run -d "$DEVICE" -t lib/main.dart \
  || fail "Simulator run failed. Send me everything above this line."
