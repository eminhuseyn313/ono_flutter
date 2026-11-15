#!/usr/bin/env bash
# Double-click to build ONO for this Mac and put it in Applications.
# Same account and data as the iPhone and the web app. Needs Xcode.
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter
flutter config --enable-macos-desktop >/dev/null 2>&1

say "Building ONO for the Mac (5–10 minutes the first time)…"
if ! run_logged build/mac-install.log flutter build macos --release -t lib/main_production.dart; then
  cat <<'MSG'

The Mac build failed. Copy the error lines above and send them to Claude.
The full log is in build/mac-install.log.
MSG
  read -r -p "Press Enter to close…" _
  exit 1
fi

APP="build/macos/Build/Products/Release/ONO.app"
[ -d "$APP" ] || fail "Built, but $APP is missing. Send build/mac-install.log to Claude."

say "Putting ONO in Applications…"
rm -rf "/Applications/ONO.app"
cp -R "$APP" /Applications/ || fail "Couldn't copy to Applications. Drag $APP there yourself."
open "/Applications/ONO.app"
say "Done. ONO is in Applications and the Dock can keep it (right-click → Options → Keep in Dock)."
read -r -p "Press Enter to close…" _
