#!/usr/bin/env bash
#
# Turns a directory of exported .xcresult attachments into committable
# screenshots: human-readable names, downscaled to roughly 1x.
#
# Device-pixel shots off an iPhone 17 Pro Max are ~2.6MB each. 1x is a few
# hundred KB for the set and is all anyone needs to judge composition,
# colour and legibility — which is the whole reason they are committed.
set -euo pipefail

SOURCE="${1:?usage: collect-screenshots.sh <exported-dir> <dest-dir>}"
DEST="${2:?usage: collect-screenshots.sh <exported-dir> <dest-dir>}"

python3 "$(dirname "$0")/rename_screenshots.py" "${SOURCE}"

mkdir -p "${DEST}"
rm -f "${DEST}"/*.png

for png in "${SOURCE}"/*.png; do
  sips -Z 956 "${png}" --out "${DEST}/$(basename "${png}")" >/dev/null
done

ls -la "${DEST}"
