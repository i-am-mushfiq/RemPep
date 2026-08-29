#!/usr/bin/env python3
"""Fail early when provisioning profiles do not match this app's targets."""

from __future__ import annotations

import argparse
import datetime as dt
import plistlib
from pathlib import Path
from typing import Any


def load(path: str) -> dict[str, Any]:
    with Path(path).open("rb") as stream:
        return plistlib.load(stream)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"Provisioning profile validation failed: {message}")


def validate_common(profile: dict[str, Any], *, label: str, team: str, bundle: str) -> dict[str, Any]:
    expiration = profile.get("ExpirationDate")
    require(isinstance(expiration, dt.datetime), f"{label} profile has no expiration date")
    now = dt.datetime.now(tz=expiration.tzinfo) if expiration.tzinfo else dt.datetime.now()
    require(expiration > now, f"{label} profile expired on {expiration.isoformat()}")

    teams = profile.get("TeamIdentifier", [])
    require(team in teams, f"{label} profile belongs to team {teams}, expected {team}")
    entitlements = profile.get("Entitlements", {})
    application_id = entitlements.get("application-identifier", "")
    require(application_id.endswith(f".{bundle}"), f"{label} application-identifier {application_id!r} does not match {bundle}")
    require(entitlements.get("com.apple.developer.team-identifier") == team, f"{label} entitlement team does not match {team}")
    return entitlements


def validate_method(profile: dict[str, Any], entitlements: dict[str, Any], method: str, label: str) -> None:
    development = bool(entitlements.get("get-task-allow"))
    device_bound = bool(profile.get("ProvisionedDevices"))
    enterprise = bool(profile.get("ProvisionsAllDevices"))
    if method == "development":
        require(development and device_bound, f"{label} is not a development profile")
    elif method == "ad-hoc":
        require(not development and device_bound and not enterprise, f"{label} is not an Ad Hoc profile")
    elif method == "app-store-connect":
        require(not development and not device_bound and not enterprise, f"{label} is not an App Store profile")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-profile", required=True)
    parser.add_argument("--widget-profile", required=True)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--bundle-id", required=True)
    parser.add_argument("--app-group", required=True)
    parser.add_argument("--icloud-container", required=True)
    parser.add_argument("--export-method", choices=("development", "ad-hoc", "app-store-connect"), required=True)
    args = parser.parse_args()

    app = load(args.app_profile)
    widget = load(args.widget_profile)
    app_entitlements = validate_common(app, label="main app", team=args.team_id, bundle=args.bundle_id)
    widget_entitlements = validate_common(widget, label="widget", team=args.team_id, bundle=f"{args.bundle_id}.widget")
    validate_method(app, app_entitlements, args.export_method, "main app profile")
    validate_method(widget, widget_entitlements, args.export_method, "widget profile")

    require(args.app_group in app_entitlements.get("com.apple.security.application-groups", []), "main app profile is missing the configured App Group")
    require(args.app_group in widget_entitlements.get("com.apple.security.application-groups", []), "widget profile is missing the configured App Group")
    require(args.icloud_container in app_entitlements.get("com.apple.developer.icloud-container-identifiers", []), "main app profile is missing the configured iCloud container")
    print("Provisioning profiles match both targets, capabilities, team, and export method.")


if __name__ == "__main__":
    main()
