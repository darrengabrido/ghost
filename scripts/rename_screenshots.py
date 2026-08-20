"""Renames exported .xcresult attachments to their human-readable names.

`xcresulttool export attachments` writes UUID filenames plus a manifest that
maps them back. Committed screenshots named after UUIDs would be unreadable
in a diff and would churn on every run, since the UUIDs are regenerated.
"""

import json
import pathlib
import re
import sys

SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}")


def attachments(node):
    """Yields every dict carrying an exportedFileName, at any depth.

    The manifest's exact nesting has changed between Xcode releases; walking
    it is cheaper than pinning to one shape and breaking on the next.
    """
    if isinstance(node, dict):
        if "exportedFileName" in node:
            yield node
        for value in node.values():
            yield from attachments(value)
    elif isinstance(node, list):
        for value in node:
            yield from attachments(value)


def main() -> int:
    source = pathlib.Path(sys.argv[1])
    manifest = source / "manifest.json"
    renamed = 0

    for entry in attachments(json.loads(manifest.read_text())):
        exported = source / entry["exportedFileName"]
        suggested = entry.get("suggestedHumanReadableName") or entry["exportedFileName"]
        if not exported.exists():
            continue
        exported.rename(source / SUFFIX.sub("", suggested))
        renamed += 1

    if renamed == 0:
        print("No attachments found in manifest.", file=sys.stderr)
        return 1

    manifest.unlink()
    print(f"Renamed {renamed} attachments.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
