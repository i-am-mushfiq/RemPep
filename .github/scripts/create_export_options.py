#!/usr/bin/env python3
"""Write ExportOptions.plist without shell interpolation or PlistBuddy quoting."""

from __future__ import annotations

import argparse
import plistlib
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    parser.add_argument("--method", choices=("development", "ad-hoc", "app-store-connect"), required=True)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--app-profile", required=True)
    parser.add_argument("--widget-profile", required=True)
    args = parser.parse_args()

    options = {
        "method": args.method,
        "signingStyle": "manual",
        "teamID": args.team_id,
        "stripSwiftSymbols": True,
        "provisioningProfiles": {
            args.bundle_id: args.app_profile,
            f"{args.bundle_id}.widget": args.widget_profile,
        },
    }
    with Path(args.output).open("wb") as stream:
        plistlib.dump(options, stream, fmt=plistlib.FMT_XML, sort_keys=True)


if __name__ == "__main__":
    main()
