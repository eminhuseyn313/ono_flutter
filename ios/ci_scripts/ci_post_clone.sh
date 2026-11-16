#!/bin/sh
# Xcode Cloud: install Flutter and prepare the iPhone build. See scripts/xcode_cloud_setup.sh.
set -e
sh "$CI_PRIMARY_REPOSITORY_PATH/scripts/xcode_cloud_setup.sh" ios
