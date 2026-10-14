#!/usr/bin/env bash
# sync_from_hub.sh — pull an app's App Store metadata, screenshots and App Preview
# videos from the hub (the source of truth) down into the app repo's fastlane/ tree,
# right before `deliver`, and VERIFY the result is complete.
#
# Screenshots/videos are read from the CANONICAL media tree owned by appstore-media
# (<slug>/media/apple/<App>/<locale>/{screenshots,app-preview}/) and flattened into
# fastlane/screenshots/<locale>/ — the layout `deliver` requires.
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
#                    [--platform ios|osx]
#
#   <slug>      the app's hub folder name  (~/Developer/app-hub/<slug>/)
#   <version>   marketing version being shipped (selects the release notes)
#   <app-repo>  the app's native project root (contains, or will get, fastlane/)
#   --hub DIR   override the hub root (default: $APP_HUB or ~/Developer/app-hub)
#   --locales   assert this exact locale set is present (else verify whatever the
#               hub has). Comma-separated, e.g. en-US,he,de-DE
#   --platform  resolve PER-PLATFORM field overrides for a universal app (one app
#               record, both iOS + macOS). A field whose value should differ by
#               platform is authored in the hub as `<field>.<platform>.txt`
#               alongside the shared `<field>.txt` — e.g.
#               `promotional_text.ios.txt` (an iOS-only promo) next to the
#               canonical `promotional_text.txt` (Mac/shared). With
#               `--platform ios`, each `<field>.ios.txt` is overlaid on top of
#               `<field>.txt` in the synced tree; the `.osx.txt` files are
#               ignored (and vice versa). WITHOUT `--platform`, all
#               `*.ios.txt`/`*.osx.txt` overrides are EXCLUDED so the synced tree
#               is the clean canonical set. Run sync once per platform, then run
#               that platform's `deliver`, before syncing the next.
#
# The hub is READ-only here; only <app-repo>/fastlane/ is written. The repo copy
# is disposable (git-ignore it) — the hub is the truth.

set -euo pipefail

slug="${1:-}"; version="${2:-}"; app_repo="${3:-}"
hub="${APP_HUB:-$HOME/Developer/app-hub}"; locales_csv=""; shot_fallback=""; platform=""
shift $(( $# < 3 ? $# : 3 )) || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hub) hub="$2"; shift 2 ;;
    --locales) locales_csv="$2"; shift 2 ;;
    --screenshot-fallback) shot_fallback="$2"; shift 2 ;;   # reuse this locale's media for locales lacking their own
    --platform) platform="$2"; shift 2 ;;                   # ios|osx — apply that platform's <field>.<platform>.txt overrides
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$slug" || -z "$version" || -z "$app_repo" ]]; then
  echo "usage: sync_from_hub.sh <slug> <version> <app-repo> [--hub DIR] [--locales a,b,c] [--screenshot-fallback LOC] [--platform ios|osx]" >&2
  exit 2
fi
if [[ -n "$platform" && "$platform" != "ios" && "$platform" != "osx" ]]; then
  echo "✗ --platform must be 'ios' or 'osx' (got '$platform')" >&2
  exit 2
fi
# the override suffix we KEEP+overlay; the other platform's overrides are dropped
other_platform=""; [[ "$platform" == "ios" ]] && other_platform="osx"
[[ "$platform" == "osx" ]] && other_platform="ios"

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

# --- 1) metadata tree (exclude the release-notes archive — it's foldered by
# version — and the per-platform override files `*.ios.txt`/`*.osx.txt`, which
# are NOT canonical fields; the matching one is overlaid below in step 1b)
if [[ $have_rsync -eq 1 ]]; then
  rsync -a --delete --exclude 'release-notes/' \
    --exclude '*.ios.txt' --exclude '*.osx.txt' "$src/metadata/" "$dst/metadata/"
else
  rm -rf "$dst/metadata"; mkdir -p "$dst/metadata"
  cp -R "$src/metadata/." "$dst/metadata/"
  rm -rf "$dst/metadata/release-notes"
  find "$dst/metadata" \( -name '*.ios.txt' -o -name '*.osx.txt' \) -delete 2>/dev/null || true
fi

# --- 1b) per-platform field overrides: overlay <field>.<platform>.txt onto
# <field>.txt for the requested platform (a universal app's iOS and macOS
# listings share one hub but a few fields — e.g. promotional_text — differ).
override_msg="(none)"
if [[ -n "$platform" ]]; then
  applied=()
  for ov in "$src/metadata"/*/*."$platform".txt; do
    [[ -e "$ov" ]] || continue
    loc="$(basename "$(dirname "$ov")")"
    field="$(basename "$ov" ".$platform.txt")"
    mkdir -p "$dst/metadata/$loc"
    cp "$ov" "$dst/metadata/$loc/$field.txt"
    applied+=("$loc/$field")
  done
  if [[ ${#applied[@]} -gt 0 ]]; then
    override_msg="$platform: ${applied[*]}"
  else
    override_msg="$platform: no <field>.$platform.txt overrides in the hub (canonical values used)"
  fi
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

# --- locales to handle: the asserted set, else whatever metadata landed
# (minus review_information, which is app-level, not a locale)
expected=()
if [[ -n "$locales_csv" ]]; then
  IFS=',' read -ra expected <<< "$locales_csv"
else
  for d in "$dst/metadata"/*/; do
    [[ -d "$d" ]] || continue
    b="$(basename "$d")"; [[ "$b" == "review_information" ]] && continue
    expected+=("$b")
  done
fi

# --- 3) screenshots + App Preview videos → FLAT fastlane/screenshots/<locale>/
# Consume the CANONICAL media tree owned by appstore-media:
#   <slug>/media/apple/<App>/<locale>/screenshots/   (upload-ready stills)
#   <slug>/media/apple/<App>/<locale>/app-preview/   (upload-ready App Preview video[s])
# deliver needs a FLAT per-locale folder (screenshots/<locale>/<files>) and CANNOT
# read the nested media tree — so copy leaf files in per locale. Videos go in the
# SAME locale folder (deliver detects them by extension). Legacy fallback: an
# already-flattened store/apple/screenshots/<locale>/.
rm -rf "$dst/screenshots"; mkdir -p "$dst/screenshots"
media="$hub/$slug/media/apple"
shots_n=0; vids_n=0; with_media=" "; no_media=()
for loc in "${expected[@]}"; do
  destloc="$dst/screenshots/$loc"; copied=0
  for appdir in "$media"/*/; do          # one <App> per root, but glob to be safe
    [[ -d "$appdir$loc/screenshots" ]] || continue
    mkdir -p "$destloc"
    for img in "$appdir$loc/screenshots"/*.png "$appdir$loc/screenshots"/*.jpg "$appdir$loc/screenshots"/*.jpeg; do
      [[ -e "$img" ]] || continue; cp "$img" "$destloc/"; shots_n=$((shots_n+1)); copied=1
    done
    for vid in "$appdir$loc/app-preview"/*.mp4 "$appdir$loc/app-preview"/*.mov "$appdir$loc/app-preview"/*.m4v; do
      [[ -e "$vid" ]] || continue; cp "$vid" "$destloc/"; vids_n=$((vids_n+1))
    done
  done
  if [[ $copied -eq 0 && -d "$src/screenshots/$loc" ]]; then   # legacy flat fallback
    mkdir -p "$destloc"; cp "$src/screenshots/$loc/"* "$destloc/" 2>/dev/null && copied=1 && shots_n=$((shots_n+1))
  fi
  if [[ $copied -eq 1 ]]; then with_media+="$loc "; else no_media+=("$loc"); fi
done

# --- reuse a fallback locale's media for locales that have text but no media of
# their own (e.g. en-GB reusing en-US English screenshots). Apple does NOT share
# screenshots across locales, so each locale needs its own copy. Opt-in only.
shot_warn=()
if [[ ${#no_media[@]} -gt 0 ]]; then
  if [[ -n "$shot_fallback" && -d "$dst/screenshots/$shot_fallback" ]]; then
    for loc in "${no_media[@]}"; do
      [[ "$loc" == "$shot_fallback" ]] && continue
      mkdir -p "$dst/screenshots/$loc"
      cp "$dst/screenshots/$shot_fallback/"* "$dst/screenshots/$loc/" 2>/dev/null || true
      with_media+="$loc(←$shot_fallback) "
    done
  else
    for loc in "${no_media[@]}"; do shot_warn+=("$loc: no screenshots in the canonical media tree (media/apple/<App>/$loc/) — deliver would ship none; add per-locale media or pass --screenshot-fallback <loc>"); done
  fi
fi
shots_msg="$shots_n still(s), $vids_n preview video(s) → $dst/screenshots/<locale>/  [locales:$with_media]"

# --- 4) VERIFY completeness -------------------------------------------------
# ($expected was computed above)

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
# merge screenshot warnings (skip empties so the array stays clean under set -u)
for w in "${shot_warn[@]:-}"; do [[ -n "$w" ]] && warn+=("$w"); done

echo "metadata: synced $src/metadata → $dst/metadata"
if [[ -n "$platform" ]]; then
  echo "platform overrides ($platform): $override_msg   [.$other_platform.txt ignored]"
fi
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
