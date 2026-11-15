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
if ! run_logged build/mac-install.log xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
    -configuration Release -derivedDataPath build/macos -allowProvisioningUpdates build; then
  SIGNED=0
  say "Signing didn't work — building without Sign in with Apple so you have ONO now…"
  if ! run_logged build/mac-install-local.log xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
      -configuration Release -derivedDataPath build/macos \
      CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
      CODE_SIGN_ENTITLEMENTS=Runner/Local.entitlements build; then
    cat <<'MSG'

The Mac build failed. Copy the error lines above and send them to Claude.
The full logs are in build/mac-install.log and build/mac-install-local.log.
MSG
    read -r -p "Press Enter to close…" _
    exit 1
  fi
fi

APP="build/macos/Build/Products/Release/ONO.app"
[ -d "$APP" ] || fail "Built, but $APP is missing. Send build/mac-install.log to Claude."

say "Putting ONO in Applications…"
rm -rf "/Applications/ONO.app"
cp -R "$APP" /Applications/ || fail "Couldn't copy to Applications. Drag $APP there yourself."
open "/Applications/ONO.app"
say "Done. ONO is in Applications and the Dock can keep it (right-click → Options → Keep in Dock)."
if [ "$SIGNED" = 0 ]; then
  cat <<'MSG'

Sign in with Apple needs the app signed with your developer team. Fix once:
  1. Xcode → Settings → Accounts: your Apple ID is listed with team XYY5Y3F4W5.
  2. Double-click "ONO on Mac" again.
Until then, sign in with your email and password (Forgot password? sets one).
MSG
fi
read -r -p "Press Enter to close…" _
