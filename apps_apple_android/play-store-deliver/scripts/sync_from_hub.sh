#!/usr/bin/env bash
# sync_from_hub.sh — pull an app's Google Play metadata from the hub (source of
# truth) down into the app repo's fastlane/metadata/android tree, before `supply`,
# and VERIFY the result is complete.
#
# The hub holds the canonical, per-locale, fastlane-format Play metadata plus the
# changelogs (by versionCode) and graphics. fastlane never authors metadata; it
# only uploads what this script mirrors in. Run it every time you supply.
#
# After syncing it verifies every required field is present and non-empty for
# every locale. If anything is missing, it reports what, points you at the skill
# that fills the hub (store-metadata-writer), and EXITS NON-ZERO so the caller
# does not upload incomplete data.
#
# Usage:
#   sync_from_hub.sh <slug> <versionCode> <app-repo> [--hub DIR] [--locales a,b,c]
#
#   <slug>         the app's hub folder name (~/Developer/app-hub/<slug>/)
#   <versionCode>  the integer versionCode being shipped (selects the changelog)
#   <app-repo>     the app's native project root
#   --hub DIR      override the hub root (default: $APP_HUB or ~/Developer/app-hub)
#   --locales      assert this exact locale set is present (comma-separated)
#
# Hub is READ-only; only <app-repo>/fastlane/ is written. The repo copy is
# disposable (git-ignore it) — the hub is the truth.

set -euo pipefail

slug="${1:-}"; vcode="${2:-}"; app_repo="${3:-}"
hub="${APP_HUB:-$HOME/Developer/app-hub}"; locales_csv=""
shift $(( $# < 3 ? $# : 3 )) || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub) hub="$2"; shift 2 ;;
    --locales) locales_csv="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$slug" || -z "$vcode" || -z "$app_repo" ]]; then
  echo "usage: sync_from_hub.sh <slug> <versionCode> <app-repo> [--hub DIR] [--locales a,b,c]" >&2
  exit 2
fi

src="$hub/$slug/store/play"
dst="$app_repo/fastlane/metadata/android"
required="title short_description full_description"   # Play per-locale required fields

if [[ ! -d "$src/metadata" ]]; then
  echo "✗ SYNC FAILED — no hub metadata at: $src/metadata" >&2
  echo "  Nothing has been authored for this app yet. Run the skill that fills the hub:" >&2
  echo "     → store-metadata-writer   (writes $slug/store/play/metadata from the profile)" >&2
  exit 1
fi
mkdir -p "$dst"

have_rsync=0; command -v rsync >/dev/null 2>&1 && have_rsync=1

# --- 1) metadata tree (exclude the changelogs archive — foldered by versionCode)
if [[ $have_rsync -eq 1 ]]; then
  rsync -a --delete --exclude 'changelogs/' "$src/metadata/" "$dst/"
else
  rm -rf "$dst"; mkdir -p "$dst"; cp -R "$src/metadata/." "$dst/"; rm -rf "$dst/changelogs"
fi

# --- 2) changelog for this versionCode → per-locale changelogs/<versionCode>.txt
#        hub layout: changelogs/<vcode>/<locale>.txt (per-locale) OR changelogs/<vcode>.txt (all locales)
if [[ -d "$src/changelogs/$vcode" ]]; then
  for f in "$src/changelogs/$vcode"/*.txt; do
    [[ -e "$f" ]] || continue
    locale="$(basename "$f" .txt)"; mkdir -p "$dst/$locale/changelogs"; cp "$f" "$dst/$locale/changelogs/$vcode.txt"
  done
elif [[ -f "$src/changelogs/$vcode.txt" ]]; then
  for ld in "$dst"/*/; do [[ -d "$ld" ]] || continue; mkdir -p "${ld}changelogs"; cp "$src/changelogs/$vcode.txt" "${ld}changelogs/$vcode.txt"; done
fi

# --- 3) graphics from media/play if present
if [[ -d "$hub/$slug/media/play" ]]; then
  if [[ $have_rsync -eq 1 ]]; then rsync -a "$hub/$slug/media/play/" "$dst/"; else cp -R "$hub/$slug/media/play/." "$dst/"; fi
  graphics_msg="synced from $hub/$slug/media/play"
else
  graphics_msg="none in hub (skipped)"
fi

# --- 4) VERIFY completeness -------------------------------------------------
expected=()
if [[ -n "$locales_csv" ]]; then
  IFS=',' read -ra expected <<< "$locales_csv"
else
  for d in "$dst"/*/; do [[ -d "$d" ]] || continue; expected+=("$(basename "$d")"); done
fi

missing=()
warn=()
if [[ ${#expected[@]} -eq 0 ]]; then
  missing+=("no locale metadata found in the hub ($src/metadata)")
else
  for loc in "${expected[@]}"; do
    d="$dst/$loc"
    if [[ ! -d "$d" ]]; then missing+=("$loc: locale folder missing"); continue; fi
    for field in $required; do
      [[ -s "$d/$field.txt" ]] || missing+=("$loc: $field.txt missing or empty")
    done
    [[ -s "$d/changelogs/$vcode.txt" ]] || warn+=("$loc: changelogs/$vcode.txt — none for versionCode $vcode")
  done
fi

echo "metadata: synced $src/metadata → $dst"
echo "graphics: $graphics_msg"

if [[ ${#missing[@]} -gt 0 ]]; then
  echo
  echo "✗ SYNC INCOMPLETE — the hub is missing required data:"
  printf '   - %s\n' "${missing[@]}"
  echo
  echo "Fill the hub, then re-sync. Run the previous skill:"
  echo "   → store-metadata-writer   (authors $slug/store/play/metadata from the profile)"
  echo "   (standalone / no hub: author the fields with play-store-metadata directly in fastlane/)"
  echo "Not uploading — incomplete metadata."
  exit 1
fi

if [[ ${#warn[@]} -gt 0 ]]; then
  echo "⚠ warnings (not blocking):"
  printf '   - %s\n' "${warn[@]}"
fi
echo "✓ sync verified — all required fields present for: ${expected[*]}"
echo "done: $src → $dst   (now run: fastlane supply)"
