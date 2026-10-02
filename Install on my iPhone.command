#!/usr/bin/env bash
# Double-click to install ONO on your iPhone so you can use it for days
# without the Mac. Needs Xcode and a USB cable (or Wi-Fi pairing).
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter

say "Looking for your iPhone…"
DEVICE=$(connected_iphone)
if [ -z "$DEVICE" ]; then
  cat <<'EOF'
No iPhone found. Do these, then press Enter:
  1. Plug the iPhone into the Mac with a cable and unlock it.
  2. Tap "Trust This Computer" on the iPhone if asked, and enter your passcode.
  3. iPhone: Settings → Privacy & Security → Developer Mode → On (the phone restarts).
     (The option appears after the phone has been plugged into a Mac with Xcode.)
EOF
  read -r -p "Press Enter when ready… " _
  DEVICE=$(connected_iphone)
  [ -n "$DEVICE" ] || fail "Still no iPhone. Open Xcode → Window → Devices and Simulators; the phone must appear there without warnings."
fi
echo "iPhone: $DEVICE"

say "Building a release version and installing it (5–10 minutes the first time)…"
if ! flutter run --release -d "$DEVICE" -t lib/main.dart --no-resident; then
  cat <<'EOF'

The build was refused — almost always signing. Fix it once:
  1. Xcode opens the project now. Click "Runner" (left, top) → target "Runner"
     → "Signing & Capabilities".
  2. Tick "Automatically manage signing" and pick your Team (your Apple ID).
     If no team is listed: Xcode → Settings → Accounts → + → sign in.
  3. Close Xcode and double-click this file again.
EOF
  open ios/Runner.xcworkspace
  fail "Signing needs a one-time setup (see above)."
fi

say "Installed. ONO is on your iPhone."
cat <<'EOF'
If the phone says "Untrusted Developer" when you open it:
  Settings → General → VPN & Device Management → your Apple ID → Trust.
You can unplug the phone now; the app keeps working on its own.
With a free Apple ID it runs for 7 days, then run this again (your data stays).
EOF
read -r -p "Press Enter to close…" _
