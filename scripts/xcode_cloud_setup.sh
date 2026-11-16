#!/bin/sh
# Shared by ios/ci_scripts and macos/ci_scripts: Xcode Cloud runs
# ci_post_clone.sh after cloning, before it builds. A fresh Apple machine
# has no Flutter, so this installs it and prepares the Flutter project
# for the platform given ("ios" or "macos").
set -e
PLATFORM=$1
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Flutter (stable) into the build machine's home.
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"
flutter config --no-analytics >/dev/null
flutter precache --"$PLATFORM"
flutter pub get

# CocoaPods comes with Xcode Cloud's Homebrew.
export HOMEBREW_NO_AUTO_UPDATE=1
command -v pod >/dev/null 2>&1 || brew install cocoapods

if [ "$PLATFORM" = ios ]; then
  # The paid-team extras (Health, widget and Lock Screen timer, Sign in
  # with Apple, the watch app), as on Emin's own TestFlight builds.
  mkdir -p ios/.capabilities
  for c in health widget apple watch; do touch "ios/.capabilities/$c"; done
  bash scripts/capabilities.sh apply
fi

# The live build (Supabase, the coach), numbered by Xcode Cloud.
flutter build "$PLATFORM" --config-only --release -t lib/main_production.dart \
  --build-number "${CI_BUILD_NUMBER:-1}"
(cd "$PLATFORM" && pod install)
