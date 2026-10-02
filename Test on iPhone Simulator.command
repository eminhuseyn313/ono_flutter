#!/usr/bin/env bash
# Double-click to run ONO in the iPhone Simulator. Needs Xcode installed.
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter

say "Opening the iPhone Simulator…"
open_simulator
DEVICE=$(booted_iphone)
if [ -z "$DEVICE" ]; then
  # Simulator.app boots its last device by itself; give it a moment.
  for _ in $(seq 1 20); do sleep 1; DEVICE=$(booted_iphone); [ -n "$DEVICE" ] && break; done
fi
if [ -z "$DEVICE" ]; then
  DEVICE=$(xcrun simctl list devices available | grep -E '^\s+iPhone' | tail -1 | grep -oE '[0-9A-F-]{36}' || true)
  [ -n "$DEVICE" ] || fail "No iPhone simulator is installed. Open Xcode → Settings → Components (or Platforms), install iOS, then run this again."
  xcrun simctl boot "$DEVICE" >/dev/null 2>&1 || true
  open_simulator
fi
echo "Simulator: $(xcrun simctl list devices | grep "$DEVICE" | sed -E 's/ \(.*//; s/^ +//')"

say "Building and launching ONO (first build takes a few minutes)…"
echo "The app appears in the Simulator window. Leave this window open; press q here to stop."
flutter run -d "$DEVICE" -t lib/main.dart \
  || fail "Simulator run failed. Send me everything above this line."
