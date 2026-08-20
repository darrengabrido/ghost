#!/usr/bin/env bash
#
# Builds Ghost, boots a simulator, installs and launches it — the whole
# loop in one command, without going through Xcode's UI.
#
# Usage: scripts/run-simulator.sh ["iPhone 17 Pro Max"]
set -euo pipefail

DEVICE="${1:-iPhone 17 Pro Max}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

DEVICE_ID=$(xcrun simctl list devices available \
  | grep "${DEVICE} (" | head -1 \
  | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')

if [ -z "${DEVICE_ID}" ]; then
  echo "error: no '${DEVICE}' simulator installed. Available iPhones:" >&2
  xcrun simctl list devices available | grep iPhone >&2 || true
  echo >&2
  echo "Install one in Xcode > Settings > Components, or pass a name:" >&2
  echo "  make run SIMULATOR='iPhone 17 Pro'" >&2
  exit 1
fi

echo "==> ${DEVICE} (${DEVICE_ID})"

xcrun simctl boot "${DEVICE_ID}" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "${DEVICE_ID}" -b

DERIVED="${REPO_ROOT}/DerivedData"
echo "==> Building"
xcodebuild -project Ghost.xcodeproj -scheme Ghost \
  -destination "id=${DEVICE_ID}" \
  -derivedDataPath "${DERIVED}" \
  -skipMacroValidation build

APP="${DERIVED}/Build/Products/Debug-iphonesimulator/Ghost.app"
[ -d "${APP}" ] || { echo "error: built app not found at ${APP}" >&2; exit 1; }

echo "==> Installing and launching"
xcrun simctl install "${DEVICE_ID}" "${APP}"
xcrun simctl launch "${DEVICE_ID}" com.ghost.app
echo "==> Ghost is running on ${DEVICE}"
