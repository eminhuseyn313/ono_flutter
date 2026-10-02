#!/usr/bin/env bash
# Double-click to open ONO in Google Chrome. No Xcode needed.
source "$(dirname "$0")/scripts/common.sh"

say "Starting ONO in Chrome (first start takes ~1 minute)…"
echo "Tip: in Chrome press Cmd+Option+I, then the phone icon, to view it at iPhone size."
echo "Press q in this window to stop."
flutter run -d chrome -t lib/main.dart || fail "Chrome run failed. Is Google Chrome installed?"
