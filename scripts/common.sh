#!/usr/bin/env bash
# Shared setup for the "Test …" launchers: get the latest main and packages.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

say() { printf '\n\033[1;33m▶ %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31m✖ %s\033[0m\n' "$1"; read -r -p "Press Enter to close…" _; exit 1; }

if ! command -v flutter >/dev/null 2>&1; then
  fail "Flutter isn't installed (or not on PATH). Install it from https://docs.flutter.dev/get-started/install/macos, then run this again."
fi

say "Getting the latest version of the app (main)…"
# Flutter and Xcode rewrite tracked files on every build (lock files, Xcode
# project settings). Set them aside so they never block the update; they stay
# recoverable with `git stash list` / `git stash pop`.
if ! git diff --quiet || ! git diff --cached --quiet; then
  git stash push -q -m "ONO launcher $(date '+%Y-%m-%d %H:%M'): files changed by Flutter/Xcode" \
    && echo "Set aside files that Flutter/Xcode changed (saved in git stash)."
fi
git checkout -q main 2>/dev/null || say "Couldn't switch to main — using the current copy."
BEFORE=$(git rev-parse --short HEAD)
if git pull -q --ff-only origin main; then
  AFTER=$(git rev-parse --short HEAD)
  [ "$BEFORE" = "$AFTER" ] && echo "Already up to date ($AFTER)." || echo "Updated $BEFORE → $AFTER."
else
  say "Couldn't update from GitHub — using the copy you already have ($BEFORE)."
fi

say "Installing packages…"
flutter pub get >/dev/null

# Re-apply opt-in iOS capabilities (Apple Health, widget) after the update.
if [ -n "$(ls ios/.capabilities 2>/dev/null)" ]; then
  say "Applying the iOS extras you turned on…"
  bash scripts/capabilities.sh apply || say "Couldn't apply them — continuing without."
fi
