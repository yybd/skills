---
name: play-store-deliver
description: >-
  The single send-surface to Google Play — sync the app's Play listing metadata,
  graphics, changelogs, AND in-app products / subscriptions from the hub source of
  truth, verify completeness, and upload them (the listing via fastlane supply, the
  in-app products via the Google Play Developer API). Use this whenever the user
  wants to push / deliver / upload Google Play listing text or graphics, publish a
  metadata-only change to a Play listing, update a changelog, or create / update a
  Play in-app product or subscription. It does NOT author content
  (that's play-store-metadata / store-metadata-writer, which write into the hub)
  and it does NOT build the APK/AAB — this skill only TRANSPORTS already-authored
  hub content to Google Play. Run it standalone for a metadata-only push, or as
  the Play half of a cross-store release. Authenticates with the Google Play
  service-account JSON referenced in the hub DATA.md. The App Store counterpart is
  app-store-deliver.
---

# Play Store Deliver — the single Google Play send-surface (supply)

The Google Play counterpart of `app-store-deliver`. Everything it sends is
**already authored** in the hub (`<slug>/store/play/…` + `media/play/`) by
`store-metadata-writer` / `play-store-metadata`. This skill **syncs it down,
verifies it, and delivers it** via `fastlane supply` (the Google Play Developer
API). It is the **one place** that uploads to Google Play.

This is the **SEND phase**, separate from authoring:

```
authoring (→ hub):  store-metadata-writer → play-store-metadata
                    write <slug>/store/play/ + media/play/   [no upload]
                              │
SEND (this skill):  play-store-deliver
                    sync_from_hub → verify (blocks if incomplete) → supply
```

## Two ways it runs
- **Standalone** — a metadata-only push (title / short / full description / graphics
  / changelog), no new AAB.
- **As the Play half of a release** — alongside the binary upload (the AAB build is
  handled by the project's own build/CI, not here).

## Auth — from the hub `DATA.md`
Use the **Google Play service-account JSON** referenced in `DATA.md` ("key fastlane
playstore"). If it isn't set there yet, that's the prerequisite — stop and ask the
user to add it (create a service account in Google Cloud, grant it in the Play
Console, download the JSON, record its path in `DATA.md`).

## Workflow

### 1. Sync from the hub, and verify
```bash
~/.claude/skills/play-store-deliver/scripts/sync_from_hub.sh <slug> <versionCode> <app-repo> [--locales en-US,iw-IL,…]
```
Mirrors `<slug>/store/play/metadata/` → `fastlane/metadata/android/`, drops the
`changelogs/<versionCode>.txt`, mirrors `media/play/` graphics, and **verifies every
required field is present per locale** (`title` / `short_description` /
`full_description`). On a miss it **reports the exact locale + field, points to
`store-metadata-writer` to fill the hub, and exits non-zero — do NOT run `supply`.**

### 2. Deliver with supply
```bash
fastlane supply --json_key "<path from DATA.md>" --skip_upload_apk true --skip_upload_aab true --validate_only true   # precheck
```
Then the real run (drop `--validate_only`). Control graphics with
`--skip_upload_images` / `--skip_upload_screenshots`. Choose the track at upload.

### 3. Deliver in-app products / subscriptions (Play Developer API)
`supply` doesn't manage in-app products — deliver them via the **Google Play
Developer API** (AndroidPublisher v3), authenticated with the same service-account
key. The IAP content is **authored by `play-store-metadata`** into the hub (this
skill only reads + uploads). For each product under `<slug>/store/play/iap/<product-id>/`:
upsert the **managed product** (`inappproducts`) — sku, status, default + per-region
price, and per-locale title/description — or the **subscription**
(`monetization.subscriptions` — base plans + per-locale listings). Verify each has
its title/description/price in the hub before upload (same block-on-missing gate);
if missing, point back to `play-store-metadata`. Full field map, auth, and a sample
lane are in [references/play-iap.md](references/play-iap.md). Skip if the app has no
Play in-app products.

### 4. Hand off the Play-Console-only leftovers
`supply` / the API can't do these — tell the user: the **Data safety** form,
**content rating (IARC)**, **pricing & countries**, app-content declarations,
creating the app entry, and any tax/compliance or subscription settings that
finalize only in the **Play Console**.

## Boundaries
- **Outward-facing — confirm before upload.** Don't author content here; fix it in
  the hub (`store-metadata-writer`) and re-sync.
- Standalone (no hub) Android-only apps author + deliver in the repo's own
  `fastlane/` directly; the hub-sync step is then a no-op.

## Reference files
- [scripts/sync_from_hub.sh](scripts/sync_from_hub.sh) — mirror the hub Play store
  tree + changelog + graphics into `fastlane/metadata/android/`, and verify.
- [references/play-iap.md](references/play-iap.md) — deliver in-app products /
  subscriptions via the Play Developer API (AndroidPublisher v3): hub layout, field
  map, auth, and a sample lane.

## Related skills
- `play-store-metadata` — **authors** the Play files into the hub (+ validates);
  this skill delivers them. (It no longer uploads.)
- `store-metadata-writer` — orchestrates the cross-store authoring into the hub.
- `app-store-deliver` — the App Store counterpart (ASC API).
