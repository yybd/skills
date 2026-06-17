---
name: app-store-deliver
description: >-
  The single send-surface to App Store Connect — sync the app's listing metadata,
  screenshots, release notes, AND in-app purchases from the hub source of truth,
  verify completeness, and upload them via the official App Store Connect API.
  Use this whenever the user wants to push / deliver / upload App Store listing
  text or screenshots, publish a metadata-only change (fix a description, swap a
  screenshot, update keywords), update or submit an In-App Purchase / Pro product
  (its per-locale display name + description, price, and the required reviewer
  screenshot), or run the metadata half of an app release. It does NOT author
  content (that's app-store-metadata / store-metadata-writer, which write into the
  hub) and it does NOT build or submit the binary (that's ship-apple-app) — this
  skill only TRANSPORTS the already-authored hub content to the store. Run it
  standalone for a metadata-only or IAP-only push, or let ship-apple-app trigger
  it during a full release. Authenticates with the App Store Connect API key (the
  .p8 path + Issuer/Key ID) from the hub DATA.md. The Google Play counterpart is
  play-store-deliver.
---

# App Store Deliver — the single send-surface (ASC API)

This skill is the **one place** that uploads to App Store Connect. Everything it
sends is **already authored** in the hub source of truth (`<slug>/store/apple/…`
+ `media/apple/`) by `store-metadata-writer` and its workers — this skill does not
write copy, it **syncs it down, verifies it, and delivers it** via the official
App Store Connect API. Listing fields, screenshots, release notes, and **in-app
purchases** all go up from here, together and consistently.

This is the **SEND phase**, cleanly separated from authoring:

```
authoring (→ hub):  store-metadata-writer → app-store-metadata · aso-keywords · appstore-media
                    write <slug>/store/apple/ + media/apple/   [no upload]
                              │
SEND (this skill):  app-store-deliver
                    sync_from_hub → verify (blocks if incomplete) → ASC API upload:
                    metadata + screenshots + IAP (localizations + price + review screenshot)
```

## Two ways it runs
- **Standalone** — a **metadata-only / IAP-only push**: fix a description, swap a
  screenshot, update keywords, or update a Pro product — no new binary. This is the
  common case.
- **From `ship-apple-app`** — during a full release, ship triggers this skill for
  the metadata/screenshots/IAP upload portion, then handles binary + submit itself.
  This skill is **not** merged into ship — ship orchestrates, this transports.

## Auth — from the hub `DATA.md`
Use the **App Store Connect API key** (token-based, official) — read the `.p8`
path + Issuer ID + Key ID from `~/Developer/app-hub/DATA.md` ("key fastlane
appstore"). Don't ask the user for them; don't use Apple-ID/session auth.

## Workflow

### 1. Sync from the hub, and verify
Pull the authored content down and confirm it's complete before any upload:
```bash
~/.claude/skills/app-store-deliver/scripts/sync_from_hub.sh <slug> <version> <app-repo> [--locales en-US,he,…]
```
It mirrors `<slug>/store/apple/metadata/` → `fastlane/metadata/`, drops the
version's release notes into each locale's `release_notes.txt`, mirrors the
screenshots, and **verifies every required field is present per locale**. If
anything is missing it **reports the exact locale + field, points to
`store-metadata-writer` to fill the hub, and exits non-zero — do NOT upload.**
Re-run after the hub is filled. (The repo `fastlane/` is a disposable artifact;
the hub is the truth.)

### 2. Deliver the listing metadata + screenshots (official ASC API)
Upload with `deliver` authenticated by the **API key** (which uses the official
App Store Connect API under the hood):
```ruby
deliver(
  api_key_path: "<.p8 + key info from DATA.md, or an app_store_connect_api_key block>",
  force: true,                 # skip the HTML preview in CI
  precheck_include_in_app_purchases: false
)
```
Do a `--verify_only` / precheck run first. Use `skip_binary_upload`,
`skip_screenshots` as appropriate for a text-only vs full push.

### 3. Deliver the in-app purchases (Pro / IAP)
`deliver` does **not** manage IAPs — upload them via the official ASC API
(`Spaceship::ConnectAPI`, token-auth with the same key). The IAP content is
**authored by `app-store-metadata`** into the hub (this skill only reads + uploads
it). For each product under `<slug>/store/apple/iap/<product-id>/`: create-or-find
the product, set the
per-locale **display name + description** (`versions=`), the **price** /
cleared-for-sale, the **review notes**, and the **required review screenshot**.
Full field map, the lane, and the hub layout are in
[references/iap-and-asc-api.md](references/iap-and-asc-api.md). Skip this step if
the app has no IAP (the README/profile `Pro:` line tells you).

### 4. Hand off the website-only leftovers
Tell the user what the API can't set: age-rating questionnaire, pricing &
availability display, the App Privacy nutrition label, export compliance, and
creating the app record if missing — then submit is `ship-apple-app`'s job.

## Boundaries
- **Outward-facing — confirm before every upload/submit.** Uploading is the user's
  call; show what will change and ask first.
- **Never author content here.** If a field is wrong or missing, fix it in the hub
  (`store-metadata-writer`) and re-sync — don't hand-edit `fastlane/` or invent copy.
- Standalone (no hub) apps author + deliver in the repo's own `fastlane/` directly;
  this skill's hub-sync step is then a no-op.

## Reference files
- [references/iap-and-asc-api.md](references/iap-and-asc-api.md) — IAP upload via
  the official ASC API (`Spaceship::ConnectAPI`): the per-locale localizations,
  pricing, review notes + screenshot, the hub layout, and a sample lane.
- [scripts/sync_from_hub.sh](scripts/sync_from_hub.sh) — mirror the hub store tree
  + version release notes + screenshots into `fastlane/`, and verify completeness.

## Related skills
- `app-store-metadata` — **authors** the listing files into the hub (+ validates
  limits); this skill delivers them. (It no longer uploads.)
- `store-metadata-writer` — orchestrates the authoring (incl. IAP) into the hub.
- `aso-keywords` — the keyword field content (authored upstream).
- `ship-apple-app` — triggers this skill for the metadata/IAP upload during a full
  release; owns the binary + submit.
- `play-store-deliver` — the Google Play counterpart (`supply`).
