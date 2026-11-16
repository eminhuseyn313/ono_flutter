# Builds the Mac app and uploads it to TestFlight (sourced by
# "ONO to TestFlight.command"). Same app record as the iPhone app:
# App Store Connect → ONO → Add Platform → macOS, once.
mac_testflight() {
  local build=$1
  local archive=build/macos/archive/ONO.xcarchive
  rm -rf "$archive" build/macos/testflight
  say "Building ONO for Mac (build $build) — about 5 minutes…"
  flutter build macos --config-only --release -t lib/main_production.dart --build-number "$build" >/dev/null 2>&1 || true
  if ! run_logged build/mac-testflight.log xcodebuild -quiet -workspace macos/Runner.xcworkspace -scheme Runner \
      -configuration Release -archivePath "$archive" -allowProvisioningUpdates archive; then
    echo "The Mac build didn't finish. Copy the error lines above and send them to Claude."
    return 1
  fi
  say "Uploading the Mac build $build to App Store Connect…"
  if ! run_logged build/mac-upload.log xcodebuild -exportArchive -archivePath "$archive" \
      -exportOptionsPlist macos/ExportOptions-TestFlight.plist \
      -exportPath build/macos/testflight -allowProvisioningUpdates; then
    cat <<'TXT'

The Mac upload was refused. The usual cause, once:
  App Store Connect → Apps → ONO → (left, under the app name) "+" / Add
  Platform → macOS. Then run this again.
TXT
    return 1
  fi
  say "Uploaded the Mac build $build."
}
