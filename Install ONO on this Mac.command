#!/usr/bin/env bash
# Double-click to build ONO for this Mac and put it in Applications.
# Same account and data as the iPhone and the web app. Needs Xcode.
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter
flutter config --enable-macos-desktop >/dev/null 2>&1

say "Building ONO for the Mac (5–10 minutes the first time)…"
# Signed with your developer team, so Sign in with Apple works. Xcode's
# signed-in account (Xcode → Settings → Accounts) makes the profile.
SIGNED=1
flutter build macos --config-only --release -t lib/main_production.dart >/dev/null 2>&1 || true
# -allowProvisioningDeviceRegistration lets Xcode add this Mac to your
# developer account the first time (Apple requires it for a signed app).
if ! run_logged build/mac-install.log xcodebuild -quiet -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Release -derivedDataPath build/macos \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration build; then
  SIGNED=0
  say "Signing didn't work — building without Sign in with Apple so you have ONO now…"
  # The unsigned build uses the entitlements without Sign in with Apple:
  # swapped in for this build only, then put back.
  cp macos/Runner/Release.entitlements build/Release.entitlements.keep
  cp macos/Runner/Local.entitlements macos/Runner/Release.entitlements
  trap 'cp build/Release.entitlements.keep macos/Runner/Release.entitlements 2>/dev/null' EXIT
  if ! run_logged build/mac-install-local.log xcodebuild -quiet -workspace macos/Runner.xcworkspace -scheme Runner \
      -configuration Release -derivedDataPath build/macos \
      CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= build; then
    cat <<'MSG'

The Mac build failed. Copy the error lines above and send them to Claude.
The full logs are in build/mac-install.log and build/mac-install-local.log.
MSG
    read -r -p "Press Enter to close…" _
    exit 1
  fi
  cp build/Release.entitlements.keep macos/Runner/Release.entitlements
fi

APP="build/macos/Build/Products/Release/ONO.app"
[ -d "$APP" ] || fail "Built, but $APP is missing. Send build/mac-install.log to Claude."

say "Putting ONO in Applications…"
rm -rf "/Applications/ONO.app"
cp -R "$APP" /Applications/ || fail "Couldn't copy to Applications. Drag $APP there yourself."
open "/Applications/ONO.app"

# Keep ONO in the Dock (once) and open it when the Mac starts.
if ! defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "/Applications/ONO.app"; then
  defaults write com.apple.dock persistent-apps -array-add \
    '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/ONO.app/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>' \
    && killall Dock 2>/dev/null
fi
osascript -e 'tell application "System Events" to if not (exists login item "ONO") then make login item at end with properties {path:"/Applications/ONO.app", hidden:false}' >/dev/null 2>&1 || true
say "Done. ONO is in the Dock and opens when your Mac starts (System Settings → General → Login Items to change that)."
if [ "$SIGNED" = 0 ]; then
  cat <<'MSG'

Sign in with Apple needs the app signed with your developer team. Fix once:
  1. Xcode → Settings → Accounts: your Apple ID is listed with team XYY5Y3F4W5.
  2. Double-click "ONO on Mac" again.
Until then, sign in with your email and password (Forgot password? sets one).
MSG
fi
read -r -p "Press Enter to close…" _
