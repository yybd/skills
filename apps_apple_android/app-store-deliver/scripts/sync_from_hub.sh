#!/usr/bin/env bash
# sync_from_hub.sh — pull an app's App Store metadata from the hub (the source of
# truth) down into the app repo's fastlane/ tree, right before `deliver`, and
# VERIFY the result is complete.
#
# The hub holds the canonical, per-locale, fastlane-format metadata and the
# release notes (by version). fastlane never authors metadata; it only uploads
# what this script mirrors in. Run it every time you deliver.
#
# After syncing, it verifies that every required field is present and non-empty
# for every locale. If anything is missing, it reports exactly what, points you
# at the skill that fills the hub (store-metadata-writer), and EXITS NON-ZERO so
# the caller does not upload incomplete data.
#
# Usage:
#   sync_from_hub.sh <slug> <version> <app-repo> [--hub DIR] [--locales a,b,c]
#
#   <slug>      the app's hub folder name  (~/Developer/app-hub/<slug>/)
#   <version>   marketing version being shipped (selects the release notes)
#   <app-repo>  the app's native project root (contains, or will get, fastlane/)
#   --hub DIR   override the hub root (default: $APP_HUB or ~/Developer/app-hub)
#   --locales   assert this exact locale set is present (else verify whatever the
#               hub has). Comma-separated, e.g. en-US,he,de-DE
#
# The hub is READ-only here; only <app-repo>/fastlane/ is written. The repo copy
# is disposable (git-ignore it) — the hub is the truth.

set -euo pipefail

slug="${1:-}"; version="${2:-}"; app_repo="${3:-}"
hub="${APP_HUB:-$HOME/Developer/app-hub}"; locales_csv=""
shift $(( $# < 3 ? $# : 3 )) || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub) hub="$2"; shift 2 ;;
    --locales) locales_csv="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$slug" || -z "$version" || -z "$app_repo" ]]; then
  echo "usage: sync_from_hub.sh <slug> <version> <app-repo> [--hub DIR] [--locales a,b,c]" >&2
  exit 2
fi

src="$hub/$slug/store/apple"
dst="$app_repo/fastlane"
required="name subtitle description keywords"   # Apple per-locale required fields

if [[ ! -d "$src/metadata" ]]; then
  echo "✗ SYNC FAILED — no hub metadata at: $src/metadata" >&2
  echo "  Nothing has been authored for this app yet. Run the skill that fills the hub:" >&2
  echo "     → store-metadata-writer   (writes $slug/store/apple/metadata from the profile)" >&2
  exit 1
fi
mkdir -p "$dst/metadata" "$dst/screenshots"

have_rsync=0; command -v rsync >/dev/null 2>&1 && have_rsync=1

# --- 1) metadata tree (exclude the release-notes archive — it's foldered by version)
if [[ $have_rsync -eq 1 ]]; then
  rsync -a --delete --exclude 'release-notes/' "$src/metadata/" "$dst/metadata/"
else
  rm -rf "$dst/metadata"; mkdir -p "$dst/metadata"
  cp -R "$src/metadata/." "$dst/metadata/"
  rm -rf "$dst/metadata/release-notes"
fi

# --- 2) this version's release notes → fastlane's per-locale release_notes.txt
rn="$src/release-notes/$version"
if [[ -d "$rn" ]]; then
  for f in "$rn"/*.txt; do
    [[ -e "$f" ]] || continue
    locale="$(basename "$f" .txt)"
    mkdir -p "$dst/metadata/$locale"
    cp "$f" "$dst/metadata/$locale/release_notes.txt"
  done
fi

# --- 3) screenshots — prefer store/apple/screenshots, else media/apple
shots=""
[[ -d "$src/screenshots" ]] && shots="$src/screenshots"
[[ -z "$shots" && -d "$hub/$slug/media/apple" ]] && shots="$hub/$slug/media/apple"
if [[ -n "$shots" ]]; then
  if [[ $have_rsync -eq 1 ]]; then rsync -a --delete "$shots/" "$dst/screenshots/"; else rm -rf "$dst/screenshots"; mkdir -p "$dst/screenshots"; cp -R "$shots/." "$dst/screenshots/"; fi
  shots_msg="synced from $shots"
else
  shots_msg="none in hub (skipped)"
fi

# --- 4) VERIFY completeness -------------------------------------------------
# locales to check: the asserted set, else whatever landed in the repo tree
expected=()
if [[ -n "$locales_csv" ]]; then
  IFS=',' read -ra expected <<< "$locales_csv"
else
  for d in "$dst/metadata"/*/; do [[ -d "$d" ]] || continue; expected+=("$(basename "$d")"); done
fi

missing=()
warn=()
if [[ ${#expected[@]} -eq 0 ]]; then
  missing+=("no locale metadata found in the hub ($src/metadata)")
else
  for loc in "${expected[@]}"; do
    d="$dst/metadata/$loc"
    if [[ ! -d "$d" ]]; then missing+=("$loc: locale folder missing"); continue; fi
    for field in $required; do
      [[ -s "$d/$field.txt" ]] || missing+=("$loc: $field.txt missing or empty")
    done
    [[ -s "$d/release_notes.txt" ]] || warn+=("$loc: release_notes.txt — none for version $version (required for updates)")
  done
fi

echo "metadata: synced $src/metadata → $dst/metadata"
echo "screenshots: $shots_msg"

if [[ ${#missing[@]} -gt 0 ]]; then
  echo
  echo "✗ SYNC INCOMPLETE — the hub is missing required data:"
  printf '   - %s\n' "${missing[@]}"
  echo
  echo "Fill the hub, then re-sync. Run the previous skill:"
  echo "   → store-metadata-writer   (authors $slug/store/apple/metadata from the profile)"
  echo "   (standalone / no hub: author the fields with app-store-metadata directly in fastlane/)"
  echo "Not uploading — incomplete metadata."
  exit 1
fi

if [[ ${#warn[@]} -gt 0 ]]; then
  echo "⚠ warnings (not blocking):"
  printf '   - %s\n' "${warn[@]}"
fi
echo "✓ sync verified — all required fields present for: ${expected[*]}"
echo "done: $src → $dst   (now run: fastlane deliver)"
echo "reminder: authenticate with the .p8 path + Issuer/Key ID from $hub/DATA.md"
