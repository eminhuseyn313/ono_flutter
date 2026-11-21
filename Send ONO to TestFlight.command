#!/usr/bin/env bash
# Double-click: build ONO for iPhone (with the watch) and Mac and send both
# to TestFlight. No questions. Your devices update from the TestFlight app.
export ONO_WHICH=3
exec "$(dirname "$0")/ONO to TestFlight.command"
