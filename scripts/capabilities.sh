#!/usr/bin/env bash
# Opt-in iOS capabilities that need your Apple team's support.
#   bash scripts/capabilities.sh health on|off   Apple Health (HealthKit)
#   bash scripts/capabilities.sh widget on|off   Home/Lock Screen widget (App Groups)
#   bash scripts/capabilities.sh status
#   bash scripts/capabilities.sh apply           re-apply (the launchers do this)
# Choices live in ios/.capabilities (not in git), so updates never lose them.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
DIR=ios/.capabilities
mkdir -p "$DIR"

find_ruby() {
  local candidates=(ruby /opt/homebrew/opt/ruby/bin/ruby /usr/local/opt/ruby/bin/ruby /usr/bin/ruby)
  for r in "${candidates[@]}"; do
    command -v "$r" >/dev/null 2>&1 || continue
    if "$r" -e "require 'xcodeproj'" >/dev/null 2>&1; then echo "$r"; return 0; fi
  done
  # Not found: install the Xcode project library for the current user.
  for r in "${candidates[@]}"; do
    command -v "$r" >/dev/null 2>&1 || continue
    echo "Installing the xcodeproj Ruby library (one time)…" >&2
    if "${r%ruby}gem" install --user-install --no-document xcodeproj >&2 2>&1 \
        && "$r" -e "require 'xcodeproj'" >/dev/null 2>&1; then
      echo "$r"; return 0
    fi
  done
  return 1
}

enabled() { for f in "$DIR"/*; do [ -f "$f" ] && basename "$f"; done; return 0; }

apply() {
  # Start from the committed project, then add what's switched on.
  git checkout -q -- ios/Runner.xcodeproj/project.pbxproj
  if [ -f ios/Runner/Runner.entitlements ] && \
     ! git ls-files --error-unmatch ios/Runner/Runner.entitlements >/dev/null 2>&1; then
    rm ios/Runner/Runner.entitlements
  fi
  local list
  list=$(enabled | tr '\n' ' ')
  [ -n "${list// /}" ] || { echo "No extra capabilities on."; return 0; }
  local ruby
  ruby=$(find_ruby) || {
    echo "Couldn't find Ruby with the xcodeproj library. Install CocoaPods (brew install cocoapods) and try again." >&2
    exit 1
  }
  # shellcheck disable=SC2086
  "$ruby" scripts/ios_capabilities.rb $list
}

case "${1:-status}" in
  health|widget)
    case "${2:-}" in
      on) touch "$DIR/$1" ;;
      off) rm -f "$DIR/$1" ;;
      *) echo "Usage: bash scripts/capabilities.sh $1 on|off" >&2; exit 2 ;;
    esac
    apply ;;
  apply) apply ;;
  status) echo "On: $(enabled | tr '\n' ' ')" ;;
  *) echo "Usage: bash scripts/capabilities.sh health|widget on|off | status | apply" >&2; exit 2 ;;
esac
