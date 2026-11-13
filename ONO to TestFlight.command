#!/usr/bin/env bash
# Double-click to build ONO and upload it to TestFlight. Then install it on
# the iPhone from the TestFlight app: no cable, and each build lasts 90 days.
# Needs the paid Apple Developer Program, Xcode signed in to that Apple ID,
# and the app created once in App Store Connect (see RELEASE.md, step 3).
source "$(dirname "$0")/scripts/common.sh"
source "$(dirname "$0")/scripts/ios.sh"

need_xcode
maybe_upgrade_flutter
ask_capabilities_once

# Every upload needs a higher build number: the number of commits on main
# only grows. (+100 keeps it above builds numbered by hand before.)
BUILD=$(( $(git rev-list --count HEAD) + 100 ))
ARCHIVE=build/ios/archive/Runner.xcarchive
rm -rf "$ARCHIVE" build/ios/testflight

say "Building ONO (build $BUILD) for the App Store — 5–10 minutes…"
# Flutter's own export step may stop at signing; the archive is what counts.
flutter build ipa --release -t lib/main_production.dart --build-number "$BUILD" || true
[ -d "$ARCHIVE" ] || fail "The build didn't finish. Scroll up for the first error (often signing: open ios/Runner.xcworkspace → Runner → Signing & Capabilities and pick your paid team)."

say "Uploading build $BUILD to App Store Connect…"
if ! xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist ios/ExportOptions-TestFlight.plist \
    -exportPath build/ios/testflight \
    -allowProvisioningUpdates; then
  cat <<'TXT'

The upload was refused. The usual causes, once each:
  1. The app doesn't exist in App Store Connect yet:
     appstoreconnect.apple.com → Apps → + → New App, iOS, name ONO,
     bundle ID com.eminhuseynzade.ono, SKU ono.
  2. Xcode isn't signed in to your paid Apple ID:
     Xcode → Settings → Accounts → + (then pick team XYY5Y3F4W5).
  3. An agreement is waiting: App Store Connect → Business → accept it.
Opening the archive in Xcode: Distribute App → App Store Connect also works.
TXT
  open "$ARCHIVE"
  fail "Upload didn't finish (see above)."
fi

say "Uploaded build $BUILD."
cat <<'TXT'
Apple processes it for 5–15 minutes (you get an email). Then:
  1. App Store Connect → ONO → TestFlight → Internal Testing → add yourself
     (once; later builds reach you automatically).
  2. On the iPhone, install "TestFlight" from the App Store, open the invite,
     and install ONO. Updates arrive there after each upload.
Your data stays on the phone and in your account; it moves across builds.
TXT
read -r -p "Press Enter to close…" _
