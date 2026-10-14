#!/usr/bin/env python3
"""
validate_metadata.py — validate fastlane deliver metadata against Apple's
character limits and required fields.

Usage:
    python3 validate_metadata.py <path>

<path> may be a project root (it will find fastlane/metadata and any per-app
subfolders), a fastlane/metadata folder, or a single per-app metadata folder.

Exit code 0 if no errors, 1 if any error-level problems found.
"""

import argparse
import json
import os
import re
import sys

# field file -> (max chars or None, severity_if_missing)
PER_LOCALE_LIMITS = {
    "name.txt": (30, "error"),
    "subtitle.txt": (30, "warn"),
    "keywords.txt": (100, "warn"),
    "description.txt": (4000, "error"),
    "promotional_text.txt": (170, "warn"),
    "release_notes.txt": (4000, "warn"),       # required for updates, not v1
    "support_url.txt": (None, "warn"),         # URL, required by 1.5
    "marketing_url.txt": (None, "info"),
    "privacy_url.txt": (None, "warn"),         # required if accounts/data
}

URL_FIELDS = {"support_url.txt", "marketing_url.txt", "privacy_url.txt"}

# Known App Store locale codes (folder names). Extend as Apple adds languages.
KNOWN_LOCALES = {
    "en-US", "en-GB", "en-AU", "en-CA", "de-DE", "fr-FR", "fr-CA", "es-ES",
    "es-MX", "it", "pt-BR", "pt-PT", "nl-NL", "sv", "da", "fi", "no", "ru",
    "pl", "tr", "ar-SA", "he", "ja", "ko", "zh-Hans", "zh-Hant", "th", "vi",
    "id", "ms", "hi", "cs", "sk", "hu", "ro", "uk", "el", "hr", "ca",
}

URL_RE = re.compile(r"^https?://[^\s]+$")


def read(path):
    try:
        with open(path, "r", errors="ignore") as f:
            return f.read().strip()
    except OSError:
        return None


def find_metadata_roots(path):
    """Return list of per-app metadata roots (folders that contain locale dirs
    and/or the shared category files)."""
    path = os.path.abspath(path)
    candidates = []
    # If user passed a project root, descend into fastlane/metadata.
    md = os.path.join(path, "fastlane", "metadata")
    base = md if os.path.isdir(md) else path
    if not os.path.isdir(base):
        return []

    def looks_like_root(d):
        try:
            children = set(os.listdir(d))
        except OSError:
            return False
        if children & KNOWN_LOCALES:
            return True
        if "copyright.txt" in children or "primary_category.txt" in children:
            return True
        return False

    if looks_like_root(base):
        candidates.append(base)
    # also check immediate subfolders (multi-app: metadata/<app>/)
    for child in sorted(os.listdir(base)):
        sub = os.path.join(base, child)
        if os.path.isdir(sub) and looks_like_root(sub):
            candidates.append(sub)
    # dedupe, keep order
    seen, out = set(), []
    for c in candidates:
        if c not in seen:
            seen.add(c)
            out.append(c)
    return out


def validate_root(root):
    issues = []  # (severity, locale_or_'-', message)
    name = os.path.basename(root.rstrip("/"))

    locale_dirs = [d for d in sorted(os.listdir(root))
                   if os.path.isdir(os.path.join(root, d)) and d != "review_information"]
    recognized = [d for d in locale_dirs if d in KNOWN_LOCALES]
    unrecognized = [d for d in locale_dirs if d not in KNOWN_LOCALES]

    if not recognized:
        issues.append(("error", "-", "no recognized locale folders found"))
    for d in unrecognized:
        issues.append(("warn", d, f"folder '{d}' is not a known App Store locale code — deliver may reject it"))

    # per-locale field checks
    for loc in recognized:
        ldir = os.path.join(root, loc)
        for fn, (limit, miss_sev) in PER_LOCALE_LIMITS.items():
            p = os.path.join(ldir, fn)
            content = read(p)
            if content is None or content == "":
                # name/description empty is serious for the primary language;
                # report at the configured severity, model decides primary.
                if miss_sev in ("error", "warn"):
                    issues.append((miss_sev, loc, f"{fn} is missing/empty"))
                continue
            if limit is not None and len(content) > limit:
                issues.append(("error", loc,
                               f"{fn} is {len(content)} chars (limit {limit}) — over by {len(content) - limit}"))
            if fn in URL_FIELDS and not URL_RE.match(content):
                issues.append(("warn", loc, f"{fn} is not a valid http(s) URL: '{content[:40]}'"))
            if fn == "keywords.txt" and ", " in content:
                issues.append(("info", loc, "keywords.txt has spaces after commas — they count toward the 100-char limit; remove them"))

    # cross-locale completeness: name present everywhere?
    names_present = {loc: bool(read(os.path.join(root, loc, "name.txt"))) for loc in recognized}
    if any(names_present.values()) and not all(names_present.values()):
        missing = [loc for loc, ok in names_present.items() if not ok]
        issues.append(("warn", "-", f"name.txt present in some locales but missing in: {', '.join(missing)} (non-primary locales fall back to primary — make sure the primary is complete)"))

    # shared required-ish
    if not read(os.path.join(root, "primary_category.txt")):
        issues.append(("warn", "-", "primary_category.txt is empty"))

    return {"app": name, "root": root, "locales": recognized, "issues": issues}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    roots = find_metadata_roots(args.path)
    if not roots:
        print("No fastlane metadata found. Expected fastlane/metadata/ with locale folders.")
        sys.exit(1)

    results = [validate_root(r) for r in roots]
    if args.json:
        print(json.dumps(results, indent=2))

    errors = 0
    sev_icon = {"error": "🔴", "warn": "🟠", "info": "⚪"}
    for res in results:
        print(f"\n=== {res['app']}  ({len(res['locales'])} locales: {', '.join(res['locales']) or 'none'}) ===")
        if not res["issues"]:
            print("  ✅ no issues")
            continue
        for sev, loc, msg in res["issues"]:
            if sev == "error":
                errors += 1
            loc_part = f"[{loc}] " if loc != "-" else ""
            print(f"  {sev_icon.get(sev, '?')} {loc_part}{msg}")

    print(f"\n{'❌' if errors else '✅'} {errors} error(s) across {len(results)} app(s).")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
