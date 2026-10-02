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
if ! git diff --quiet || ! git diff --cached --quiet; then
  say "You have local edits — keeping them and skipping the update."
else
  git checkout -q main
  git pull -q --ff-only origin main || say "Couldn't update from GitHub — using the copy you already have."
fi

say "Installing packages…"
flutter pub get >/dev/null
