#!/usr/bin/env python3
"""Reject common personal-information and signing-material leaks in source control."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
THIS_SCRIPT = Path(__file__).resolve()
SKIP_PARTS = {".git", "DerivedData", "build", "xcuserdata", "__pycache__"}
FORBIDDEN_SUFFIXES = {".p12", ".pfx", ".mobileprovision", ".cer", ".key", ".pem"}
PATTERNS = {
    "email address": re.compile(r"(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
    "Windows user path": re.compile(r"[A-Za-z]:[\\/]Users[\\/][^\\/\s]+", re.IGNORECASE),
    "macOS user path": re.compile(r"/Users/[^/\s]+"),
    "Linux home path": re.compile(r"/home/[^/\s]+"),
    "GitHub account URL": re.compile(r"https?://github\.com/(?!actions(?:/|$))[^/\s]+/?", re.IGNORECASE),
    "private key or certificate": re.compile(r"-----BEGIN (?:.*PRIVATE KEY|CERTIFICATE)-----"),
    "committed Apple team ID": re.compile(r"DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}\s*;"),
}


def main() -> None:
    failures: list[str] = []
    for path in ROOT.rglob("*"):
        if (
            not path.is_file()
            or path.resolve() == THIS_SCRIPT
            or any(part in SKIP_PARTS for part in path.parts)
        ):
            continue
        relative = path.relative_to(ROOT)
        if path.suffix.lower() in FORBIDDEN_SUFFIXES or path.name == ".env":
            failures.append(f"{relative}: signing material or environment file must not be committed")
            continue
        data = path.read_bytes()
        if b"\x00" in data[:4096]:
            continue
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in PATTERNS.items():
            if pattern.search(text):
                failures.append(f"{relative}: contains a possible {label}")

    if failures:
        raise SystemExit("Repository privacy check failed:\n" + "\n".join(f"- {item}" for item in failures))
    print("Repository privacy check passed: no common identity or signing-material leaks found.")


if __name__ == "__main__":
    main()
