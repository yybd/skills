#!/usr/bin/env python3
"""Validate Google Play listing metadata (fastlane `supply` layout).

Checks each locale under ``fastlane/metadata/android/`` against Google's
character limits, required fields, and graphic assets, and prints a report.
Exits non-zero if any hard error is found. The Android counterpart of the Apple
``validate_metadata.py``.

Usage:
    python3 validate_metadata.py <project-root-or-android-metadata-root>
"""
from __future__ import annotations

import sys
from pathlib import Path

ANDROID_PARTS = ("fastlane", "metadata", "android")

# Field -> max characters (Play counts Unicode characters).
LIMITS = {"title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000}
REQUIRED = ("title.txt", "short_description.txt", "full_description.txt")
CHANGELOG_LIMIT = 500


def resolve_android_root(root: Path) -> Path:
    if root.parts[-3:] == ANDROID_PARTS:
        return root
    cand = root.joinpath(*ANDROID_PARTS)
    return cand if cand.is_dir() else root


def char_len(p: Path) -> int:
    # Play doesn't count a trailing newline; strip a single one.
    return len(p.read_text(encoding="utf-8").rstrip("\n"))


def has_real_files(d: Path) -> bool:
    """True if the folder holds a non-dotfile (ignores .gitkeep / .DS_Store)."""
    return d.is_dir() and any(not c.name.startswith(".") for c in d.iterdir())


def validate(android_root: Path) -> int:
    if not android_root.is_dir():
        print(f"ERROR: not a directory: {android_root}")
        return 1

    locales = sorted(d for d in android_root.iterdir() if d.is_dir())
    if not locales:
        print(f"ERROR: no locale folders under {android_root}")
        return 1

    errors = 0
    warnings = 0
    print(f"Validating Play metadata under: {android_root}\n")

    for loc in locales:
        print(f"[{loc.name}]")

        # Required text fields + limits.
        for name in REQUIRED:
            f = loc / name
            if not f.exists() or char_len(f) == 0:
                print(f"  ERROR  {name}: missing or empty (required)")
                errors += 1
                continue
            n = char_len(f)
            limit = LIMITS[name]
            if n > limit:
                errors += 1
                print(f"  ERROR  {name}: {n}/{limit} chars (over limit)")
            else:
                print(f"  ok     {name}: {n}/{limit} chars")

        # Optional promo video URL.
        v = loc / "video.txt"
        if v.exists() and char_len(v) > 0:
            if not v.read_text(encoding="utf-8").strip().startswith("http"):
                print("  WARN   video.txt: present but not a URL")
                warnings += 1

        # Changelogs.
        changelogs = loc / "changelogs"
        if changelogs.is_dir():
            for f in sorted(changelogs.glob("*.txt")):
                n = char_len(f)
                if n > CHANGELOG_LIMIT:
                    errors += 1
                    print(f"  ERROR  changelogs/{f.name}: {n}/{CHANGELOG_LIMIT} chars (over limit)")
                else:
                    print(f"  ok     changelogs/{f.name}: {n}/{CHANGELOG_LIMIT} chars")

        # Graphics (warn-level — needed to publish, but may be added later / shared).
        if not has_real_files(loc / "images" / "featureGraphic"):
            print("  WARN   images/featureGraphic/: empty (1024x500 required to publish)")
            warnings += 1
        if not has_real_files(loc / "images" / "icon"):
            print("  WARN   images/icon/: empty (512x512 store icon)")
            warnings += 1

        phone = loc / "images" / "phoneScreenshots"
        shots = [c for c in phone.iterdir() if not c.name.startswith(".")] if phone.is_dir() else []
        if len(shots) < 2:
            print(f"  WARN   images/phoneScreenshots/: {len(shots)} (need 2-8)")
            warnings += 1

        print()

    print(f"Done. {errors} error(s), {warnings} warning(s).")
    return 1 if errors else 0


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python3 validate_metadata.py <project-root-or-android-metadata-root>")
        sys.exit(2)
    root = Path(sys.argv[1]).expanduser().resolve()
    sys.exit(validate(resolve_android_root(root)))


if __name__ == "__main__":
    main()
