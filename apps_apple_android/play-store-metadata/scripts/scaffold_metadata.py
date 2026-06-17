#!/usr/bin/env python3
"""Scaffold the fastlane `supply` metadata tree for Google Play.

Creates ``fastlane/metadata/android/<locale>/`` with the standard text files and
image folders, non-destructively (never overwrites existing content). The Android
counterpart of the Apple ``scaffold_metadata.py``.

Usage:
    python3 scaffold_metadata.py <root> --locales en-US,de-DE,iw-IL

``<root>`` may be the project root (the script appends fastlane/metadata/android)
or the android metadata root itself.
"""
from __future__ import annotations

import argparse
from pathlib import Path

ANDROID_PARTS = ("fastlane", "metadata", "android")

# Text files created empty in each locale.
TEXT_FILES = ("title.txt", "short_description.txt", "full_description.txt", "video.txt")

# Image folders created in each locale (kept with a .gitkeep so they survive git).
IMAGE_DIRS = (
    "images/icon",
    "images/featureGraphic",
    "images/phoneScreenshots",
    "images/sevenInchScreenshots",
    "images/tenInchScreenshots",
)


def resolve_android_root(root: Path) -> Path:
    """Accept either the project root or the android metadata root."""
    if root.parts[-3:] == ANDROID_PARTS:
        return root
    return root.joinpath(*ANDROID_PARTS)


def scaffold(android_root: Path, locales: list[str]) -> None:
    created: list[str] = []
    skipped: list[str] = []

    for loc in locales:
        locdir = android_root / loc
        (locdir / "changelogs").mkdir(parents=True, exist_ok=True)
        for d in IMAGE_DIRS:
            img = locdir / d
            img.mkdir(parents=True, exist_ok=True)
            keep = img / ".gitkeep"
            if not keep.exists():
                keep.write_text("", encoding="utf-8")
        for name in TEXT_FILES:
            f = locdir / name
            if f.exists():
                skipped.append(str(f))
            else:
                f.write_text("", encoding="utf-8")
                created.append(str(f))

    print(f"Android metadata root: {android_root}")
    print(f"Locales: {', '.join(locales)}")
    print(f"Created {len(created)} file(s); left {len(skipped)} existing untouched.")
    for c in created:
        print(f"  + {c}")
    for s in skipped:
        print(f"  = {s} (exists)")


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Scaffold fastlane supply metadata for Google Play (non-destructive)."
    )
    ap.add_argument("root", help="Project root, or the fastlane/metadata/android root.")
    ap.add_argument(
        "--locales",
        required=True,
        help="Comma-separated Play locale codes, e.g. en-US,de-DE,iw-IL",
    )
    args = ap.parse_args()

    locales = [l.strip() for l in args.locales.split(",") if l.strip()]
    if not locales:
        ap.error("no locales given")

    android_root = resolve_android_root(Path(args.root).expanduser().resolve())
    scaffold(android_root, locales)


if __name__ == "__main__":
    main()
