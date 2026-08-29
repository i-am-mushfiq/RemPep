#!/usr/bin/env python3
"""Create a temporary simulator from the newest installed iOS runtime."""

from __future__ import annotations

import json
import re
import subprocess


def command(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def version_tuple(value: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r"\d+", value))


runtimes = json.loads(command("xcrun", "simctl", "list", "runtimes", "--json"))["runtimes"]
ios_runtimes = [item for item in runtimes if item.get("isAvailable") and "SimRuntime.iOS" in item["identifier"]]
if not ios_runtimes:
    raise SystemExit("No available iOS simulator runtime is installed")
runtime = max(ios_runtimes, key=lambda item: version_tuple(item.get("version", "0")))

device_types = json.loads(command("xcrun", "simctl", "list", "devicetypes", "--json"))["devicetypes"]
iphones = [item for item in device_types if item.get("productFamily") == "iPhone" or item["name"].startswith("iPhone")]
if not iphones:
    raise SystemExit("No iPhone simulator device type is installed")
preferred = next((item for item in iphones if item["name"] == "iPhone 17 Pro"), iphones[0])

udid = command("xcrun", "simctl", "create", "Connect-CI", preferred["identifier"], runtime["identifier"])
print(udid)
