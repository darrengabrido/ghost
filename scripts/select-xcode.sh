#!/usr/bin/env bash
#
# Selects the newest installed Xcode by version and verifies it carries an
# iOS 26+ SDK, which Ghost's deployment target requires.
#
# Selecting by name sort looks correct and is not: runners carry both
# Xcode_26.3.app and a bare Xcode.app, and locale collation ignores
# punctuation, so "Xcode.app" sorts last and wins — silently handing you
# Xcode 16.4 and an iOS 18.5 SDK on a machine that has 26.3.
set -euo pipefail

echo "Available Xcodes:"
ls /Applications | grep -i Xcode || true

XCODE_APP=""
BEST_VERSION=""
for app in /Applications/Xcode*.app; do
  version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "${app}/Contents/Info.plist" 2>/dev/null) || continue
  if [ -z "${BEST_VERSION}" ] || \
     [ "$(printf '%s\n%s\n' "${BEST_VERSION}" "${version}" | sort -V | tail -1)" = "${version}" ]; then
    BEST_VERSION="${version}"
    XCODE_APP="${app}"
  fi
done

if [ -z "${XCODE_APP}" ]; then
  echo "::error::No Xcode found in /Applications."
  exit 1
fi

echo "Using ${XCODE_APP} (Xcode ${BEST_VERSION})"
sudo xcode-select -s "${XCODE_APP}/Contents/Developer"
xcodebuild -version

if ! xcodebuild -showsdks | grep -qE "iphoneos(2[6-9]|[3-9][0-9])"; then
  echo "::error::No iOS 26+ SDK on this runner. Ghost's deployment target is iOS 26.0."
  xcodebuild -showsdks
  exit 1
fi
