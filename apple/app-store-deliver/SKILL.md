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

> **Conversational language:** talk to the user — questions, summaries, reports — in the `conversational language` set in the hub `DATA.md` (`~/Developer/app-hub/DATA.md`; currently `hebrew`); fall back to the language the user writes in if it is unset (e.g. a standalone project with no hub). This sets the *conversation* language only — content/deliverables follow the app's target locales.

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
~/.claude/skills/app-store-deliver/scripts/sync_from_hub.sh <slug> <version> <app-repo> \
    [--locales en-US,he,…] [--screenshot-fallback en-US] [--platform ios|osx]
```

**Per-platform field overrides (universal apps).** A universal app is ONE App
Store record with BOTH an iOS and a macOS version (same bundle id), so most
listing text is shared — but a few fields read better differently per platform
(classically the **promotional text**: the Mac listing announces "Now on iPhone
and iPad", while the iOS listing should cross-promote "Also on Mac — one
Universal Purchase"). Author the platform-specific value in the hub as
`<field>.<platform>.txt` next to the canonical `<field>.txt`, e.g.
`store/apple/metadata/en-US/promotional_text.ios.txt`. Then sync **once per
platform** and deliver that platform before syncing the next:
```bash
sync_from_hub.sh <slug> <ver> <repo> --platform osx   # canonical text (.ios.txt/.osx.txt resolved/ignored)
fastlane … platform:osx …                              # deliver macOS
sync_from_hub.sh <slug> <ver> <repo> --platform ios   # overlays *.ios.txt onto the shared fields
fastlane … platform:ios …                              # deliver iOS
```
`--platform ios` overlays every `<field>.ios.txt` onto `<field>.txt` (and ignores
`.osx.txt`), and vice versa. WITHOUT `--platform`, all `*.ios.txt`/`*.osx.txt`
are excluded and you get the clean canonical set. The override is just text in the
hub — promo text is editable on a live version without resubmission, so an
iOS-only promo can also be pushed standalone via the ASC API
(`appStoreVersionLocalizations` PATCH `promotionalText`) without re-running deliver.

Screenshots are **per-locale on the App Store** (Apple doesn't share them across
locales). A locale can have authored text but no media of its own — the sync then
**warns** it would ship no screenshots. `--screenshot-fallback <loc>` reuses that
locale's stills+video for any locale lacking its own (e.g. `en-GB` reusing the
English `en-US` capture).
It mirrors `<slug>/store/apple/metadata/` → `fastlane/metadata/`, drops the
version's release notes into each locale's `release_notes.txt`, flattens the
canonical media tree (`media/apple/<App>/<locale>/{screenshots,app-preview}/`,
owned by `appstore-media`) into `fastlane/screenshots/<locale>/` — the flat layout
`deliver` requires, stills and the App Preview video together — and **verifies
every required field is present per locale**. If
anything is missing it **reports the exact locale + field, points to
`store-metadata-writer` to fill the hub, and exits non-zero — do NOT upload.**
Re-run after the hub is filled. (The repo `fastlane/` is a disposable artifact;
the hub is the truth.)

### 2. Deliver the listing metadata + screenshots (official ASC API)
Upload with `deliver` authenticated by the **API key** (official ASC API under the
hood). For a **Mac app, `platform: "osx"` is required** (default is ios):
```ruby
deliver(
  api_key: app_store_connect_api_key(key_id: "…", issuer_id: "…", key_filepath: "…"),  # from DATA.md
  platform: "osx",                       # REQUIRED for Mac apps
  app_identifier: "<bundle id>",
  force: true,                           # skip the HTML preview
  skip_binary_upload: true,              # metadata-only push
  overwrite_screenshots: true,
  overwrite_preview_videos: true,
  run_precheck_before_submit: false,     # not submitting here
  submit_for_review: false,
  precheck_include_in_app_purchases: false
)
```
**Push text and media in two passes** — more robust against the screenshot upload
flakiness (see Gotchas): first `skip_screenshots: true` (text lands cleanly), then
`skip_metadata: true` (media). After the media pass, verify on ASC and **dedup**
with `scripts/dedup_screenshots.rb`.

> **No `verify_only` for a metadata-only push** — it crashes when there's no binary
> (`Digest::MD5.hexdigest(nil)`). Instead validate field lengths yourself (name ≤30,
> subtitle ≤30, keywords ≤100, promo ≤170, description/notes ≤4000) and run the real
> upload (it correctly skips the binary).

**App Preview video:** `deliver` does **not** upload it (it processes only stills).
Upload it separately with `scripts/upload_app_preview.rb` (`DESKTOP` preview type
for Mac) — the sync already places the video in `fastlane/screenshots/<locale>/`.

### 3. Deliver the in-app purchases (Pro / IAP)
`deliver` does **not** manage IAPs, and there is **no ConnectAPI IAP model** —
drive the raw ASC endpoints with the token client (or use `scripts/deliver_iap.rb`).
The IAP content is **authored by `app-store-metadata`** into the hub (this skill
only reads + uploads it). For each product under `<slug>/store/apple/iap/<product-id>/`:
create-or-find the product, set the per-locale **display name + description**, the
**review note**, the **price** / cleared-for-sale, and the **required reviewer
screenshot** — but **read the IAP's relationships first**: price and screenshot are
often already set in ASC, so skip what's done. Setting localization + review note +
price + screenshot flips state to `READY_TO_SUBMIT`; it ships **attached to the next
app-version submission** (don't submit it standalone). The full endpoint map, the
working recipe, and the hub layout are in
[references/iap-and-asc-api.md](references/iap-and-asc-api.md). Skip this step if the
app has no IAP (the README/profile `Pro:` line tells you).

### 4. Hand off the website-only leftovers
Tell the user what the API can't set: age-rating questionnaire, pricing &
availability display, the App Privacy nutrition label, export compliance, and
creating the app record if missing — then submit is `ship-apple-app`'s job.

## Gotchas (hard-won, verified against fastlane 2.234)
- **Mac needs `platform: "osx"`** — deliver defaults to ios; without this it targets
  the wrong (or no) version.
- **Screenshot upload is flaky** — the ASC API can return `500` on deliver's
  post-upload verification, which triggers retries that leave **duplicate
  screenshots** in a set. Always verify the set after a media push and run
  `scripts/dedup_screenshots.rb` (keeps one of each fileName, reorders).
- **`verify_only` crashes** with no binary (`Digest::MD5.hexdigest(nil)`). Don't use
  it for metadata-only; validate lengths + run the real upload (it skips the binary).
- **App Preview videos are NOT uploaded by deliver** — it silently processes only
  stills. Use `scripts/upload_app_preview.rb` (reserve→upload→commit + poll).
- **deliver never removes locales** — a locale present in ASC but absent from the hub
  (e.g. a stale one from a rename) **persists** and would ship its old copy. To drop
  it, delete the `appStoreVersionLocalization` (and the `appInfoLocalization` for the
  name/subtitle) via the API. Mirroring the hub does not clean it up.
- **The app NAME/subtitle live on the editable `appInfo`** (not the version). A live
  version keeps showing its approved name; check the `PREPARE_FOR_SUBMISSION` appInfo,
  not `appInfos.first`.
- **IAP single resource is `v2/inAppPurchases/{id}`**; sub-resources only resolve via
  the resource's `relationships.*.links.related` URLs. See the IAP reference.

## Boundaries
- **Outward-facing — confirm before every upload/submit.** Uploading is the user's
  call; show what will change and ask first.
- **Never author content here.** If a field is wrong or missing, fix it in the hub
  (`store-metadata-writer`) and re-sync — don't hand-edit `fastlane/` or invent copy.
- Standalone (no hub) apps author + deliver in the repo's own `fastlane/` directly;
  this skill's hub-sync step is then a no-op.

## Reference files
- [references/iap-and-asc-api.md](references/iap-and-asc-api.md) — IAP upload via the
  raw ASC API (token client): the endpoint map, the per-locale localizations, review
  note, pricing + screenshot, the hub layout, and a working recipe.
- [scripts/sync_from_hub.sh](scripts/sync_from_hub.sh) — mirror the hub store tree +
  version release notes, flatten the canonical media tree (stills + App Preview video)
  into `fastlane/screenshots/<locale>/`, and verify completeness.
- [scripts/asc_common.rb](scripts/asc_common.rb) — shared token auth (key from the hub
  `DATA.md`) + raw `get/post/patch/delete` client used by the Ruby helpers below.
- [scripts/deliver_iap.rb](scripts/deliver_iap.rb) — deliver an IAP's per-locale
  display name + description + review note (idempotent create-or-update).
- [scripts/upload_app_preview.rb](scripts/upload_app_preview.rb) — upload an App
  Preview video (deliver can't); `DESKTOP` for Mac, polls processing, sets poster frame.
- [scripts/dedup_screenshots.rb](scripts/dedup_screenshots.rb) — remove duplicate
  screenshots and fix ordering after a flaky deliver run (`--dry-run` to inspect).

## Related skills
- `app-store-metadata` — **authors** the listing files into the hub (+ validates
  limits); this skill delivers them. (It no longer uploads.)
- `store-metadata-writer` — orchestrates the authoring (incl. IAP) into the hub.
- `aso-keywords` — the keyword field content (authored upstream).
- `ship-apple-app` — triggers this skill for the metadata/IAP upload during a full
  release; owns the binary + submit.
- `play-store-deliver` — the Google Play counterpart (`supply`).
