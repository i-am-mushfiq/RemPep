#!/usr/bin/env python3
"""Apply CI-owned Apple identifiers without exposing them as source defaults."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


IDENTIFIER = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]+$")
ROOT = Path(__file__).resolve().parents[2]


def valid(value: str, label: str) -> str:
    if not IDENTIFIER.fullmatch(value) or ".." in value or value.endswith("."):
        raise SystemExit(f"Invalid {label}: {value!r}")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--icloud-container", required=True)
    parser.add_argument("--app-group", required=True)
    args = parser.parse_args()

    bundle = valid(args.bundle_id, "bundle identifier")
    cloud = valid(args.icloud_container, "iCloud container")
    group = valid(args.app_group, "App Group")
    if not cloud.startswith("iCloud."):
        raise SystemExit("The iCloud container must start with 'iCloud.'")
    if not group.startswith("group."):
        raise SystemExit("The App Group must start with 'group.'")

    replacements = {
        "iCloud.com.connect.relationships": cloud,
        "group.com.connect.relationships": group,
        "com.connect.relationships.widget": f"{bundle}.widget",
        "com.connect.relationships": bundle,
    }
    roots = [ROOT / "Connect", ROOT / "ConnectWidget", ROOT / "Connect.xcodeproj"]
    suffixes = {".swift", ".plist", ".entitlements", ".pbxproj"}
    totals = {key: 0 for key in replacements}

    for root in roots:
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in suffixes:
                continue
            text = path.read_text(encoding="utf-8")
            changed = text
            for old, new in replacements.items():
                totals[old] += changed.count(old)
                changed = changed.replace(old, new)
            if changed != text:
                path.write_text(changed, encoding="utf-8")

    missing = [token for token, count in totals.items() if count == 0]
    if missing:
        raise SystemExit(f"Expected placeholder(s) not found: {', '.join(missing)}")
    print(f"Configured {bundle} and {bundle}.widget")


if __name__ == "__main__":
    main()
