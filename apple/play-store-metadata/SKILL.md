---
name: play-store-metadata
description: >-
  Create, organize, and validate Google Play Store listing metadata for an
  Android app using fastlane supply — localized text (title, short description,
  full description, release notes / changelogs, promo video URL) and the store
  graphics (512×512 icon, 1024×500 feature graphic, phone & tablet screenshots),
  per locale under the hub store tree (or fastlane/metadata/android/ when
  standalone). Use this whenever the user wants to prepare, write, translate, fix,
  or validate Google Play / Play Console listing text or graphics, set up the
  fastlane supply structure, manage multi-language Play listings, improve Play
  store discoverability / ASO, or get assets into Play's required sizes. It
  scaffolds the per-locale file tree, validates against Google's character limits
  and required fields, folds in Play ASO (Play has no keywords field, so
  discoverability lives in the visible text), and tells the user which steps are
  Play-Console-only. It does NOT upload — the actual `supply` delivery to Google
  Play is the play-store-deliver skill; this skill authors and validates the
  content it sends.
---

# Google Play Store Metadata (fastlane supply)

> **Conversational language:** talk to the user — questions, summaries, reports — in the `conversational language` set in the hub `DATA.md` (`~/Developer/app-hub/DATA.md`; currently `hebrew`); fall back to the language the user writes in if it is unset (e.g. a standalone project with no hub). This sets the *conversation* language only — content/deliverables follow the app's target locales.

Getting a Play listing published means every localized field is present, within
Google's character limits, and consistent across languages — and that the things
that can't be set programmatically (the Data safety form, the content-rating
questionnaire, pricing) get done on the Play Console website. This skill **authors
and validates** that metadata; the actual `supply` upload is the
**`play-store-deliver`** skill.

Guide the user — don't just generate files. Listing copy is a product/marketing
decision; ask for the positioning and translate intent faithfully rather than
inventing claims. Confirm before installing tools or uploading.

> This is the Android counterpart of the **`app-store-metadata`** skill (Apple).
> In the **BD TECH studio flow**, cross-store coordination belongs to
> `store-metadata-writer` (Hub): it lifts one copy block from the app's profile
> (`~/Developer/app-hub/<slug>/profile.md`), keeps Apple and Play consistent, and
> drives this skill for the Play file mechanics — so when a profile exists, take
> the copy from there, don't independently re-author or translate it here.
> Standalone (no profile): if the app **also ships on Apple**, lift the shared copy
> (Play title ≈ App name, short description ≈ subtitle, full description from the
> feature list) from the repo's `README.md` — the `app-identity` skill's source of truth
> — to keep Play consistent with the App Store. For an Android-only project (no
> README), write the copy with the user. Either way, adapt per store (Play has no
> keywords field — see step 7).

## Where the canonical metadata lives (hub vs repo)

- **BD TECH (hub) flow — the source of truth is the hub:**
  `~/Developer/app-hub/<slug>/store/play/metadata/<locale>/…`, with changelogs by
  `versionCode` at `<slug>/store/play/changelogs/<versionCode>.txt` and graphics
  under `<slug>/media/play/`. Scaffold, write, and validate **there**. Default URLs
  come from the hub `DATA.md` (the Play service-account key goes there too, under
  "key fastlane playstore", when present).
- **Standalone flow (no hub)** — author directly in the app repo's
  `fastlane/metadata/android/<locale>/…`.

This skill **authors + validates** the content; it does **not** upload. The delivery
to Google Play — sync hub → `fastlane/`, the `supply` upload — is the
**`play-store-deliver`** skill. Hand off to it once the content is authored and validated.

## Workflow

### 1. Check fastlane (supply)
Detect whether fastlane is set up:
- `fastlane/` directory with a `Fastfile` and/or `metadata/android/`,
- `fastlane` in the `Gemfile`, or `which fastlane` / `bundle exec fastlane`.

`supply` is the Android counterpart of Apple's `deliver`. Scaffolding and
validating metadata locally needs no credentials; **uploading** needs a Google
Play service-account JSON. If fastlane is missing, guide installation (ask first —
it changes the environment). Install and auth steps are in
[references/metadata-spec.md](references/metadata-spec.md#fastlane-supply-setup).
Prefer Bundler (`Gemfile` + `bundle install`) so the version is pinned.

### 2. Understand the listing shape
- **One app or several** — product flavors / `applicationId`s each map to their own
  `supply` package name and metadata path (detect this; don't assume one app).
- **Release track** — production / beta / alpha / internal. Changelogs attach per
  `versionCode`; the track is chosen at upload.
- **versionCode** — read it from `build.gradle` (`versionCode`); changelog files
  are named for the integer versionCode (e.g. `changelogs/42.txt`).

### 2a. Ask which languages — ALWAYS ask, never assume
Language choice is the user's decision and shapes everything downstream (how many
files, how much copy to write/translate, screenshot locales). So:

1. First detect what already exists — list the locale folders currently under
   `metadata/android/` so the user sees the starting point.
2. Then ASK explicitly: **single language or multiple?** (don't default to
   multi — one locale is a legitimate, common choice), and **which specific
   languages?**
3. Map each chosen language to its **Play locale code** (`en-US`, `de-DE`,
   `es-419`, `ja-JP`, …). The full list and the **Hebrew gotcha — Play uses
   `iw-IL`, the legacy code, not `he`** — are in
   [references/metadata-spec.md](references/metadata-spec.md#locale-codes).

Use the AskUserQuestion tool when available — it's exactly the branching decision
(single vs multi, and which set) the user should drive. Only scaffold once the
language set is confirmed.

### 3. Ask: text only, or text + graphics
This changes the work substantially, so ask up front:
- **Text only** — fastest; title, short/full description, changelog.
- **Text + graphics** — also the feature graphic (mandatory to publish), icon,
  and screenshots (step 5).

### 4. Create / update the metadata files
Scaffold the per-locale structure (non-destructive — won't overwrite existing
content):
```bash
python3 ~/.claude/skills/play-store-metadata/scripts/scaffold_metadata.py <project-root> --locales en-US,de-DE,iw-IL
```
In the BD TECH flow, scaffold and validate against the **hub** store path
`~/Developer/app-hub/<slug>/store/play` (the source of truth); standalone, against
the repo's `fastlane/` as above.

Then fill the fields. In the BD TECH studio flow the wording comes from the
profile (via `store-metadata-writer`); standalone, take the shared copy from the
app's `README.md` (the `app-identity` skill's source of truth) when it also ships on
Apple — else write the base language with the user — then translate to the others,
keeping each field within its limit (the translated string, not the source, must
fit). Field list, limits, and which files are per-locale vs shared are in
[references/metadata-spec.md](references/metadata-spec.md#text-fields--limits).

### 5. Graphics (only if chosen)
- **Feature graphic 1024×500** (PNG/JPEG, no alpha) — **mandatory** for the
  listing to go live; unique to Play, no Apple analog.
- **Icon 512×512** (32-bit PNG) — the store icon (the launcher icon ships inside
  the app bundle separately).
- **Screenshots** — 2–8 per type, phone plus optional 7"/10" tablet; min side
  ≥320px, max side ≤3840px, max aspect 2:1.

There is **no** iOS-snapshot-style capture automation. Capture manually, or use
`fastlane screengrab` for an instrumented app. Sizes and the full asset list are
in [references/metadata-spec.md](references/metadata-spec.md#graphics).

### 5b. In-app products / subscriptions — author into the hub
If the app sells Play in-app products, **this skill authors their metadata** (the
deliver skill only syncs + uploads). Write each into the hub at
`<slug>/store/play/iap/<product-id>/` (`<locale>/title.txt` + `<locale>/description.txt`,
`price.txt`, type). Lift the copy from the profile/README — don't invent. Play
**managed products / subscriptions** are delivered by **`play-store-deliver`** via the
Play Developer API (AndroidPublisher v3), not `supply` — author them here, it uploads them.

### 6. Validate against Google's requirements
Always validate before uploading — over-limit fields, a missing feature graphic,
or fewer than two screenshots are the common Play listing rejections:
```bash
python3 ~/.claude/skills/play-store-metadata/scripts/validate_metadata.py <project-root>
```
It checks character limits, required fields per locale, changelog limits, and
graphic presence, and prints a report. Fix every error it flags.

### 7. ASO — Play has no keywords field
Unlike the App Store (a hidden 100-character keywords field), Google Play indexes
the **visible** text — the title, short description, and full description. So
discoverability is a copy concern, not a separate field:
- put the single most important search term in the **title** (within 30 chars);
- lead the **short description** with the primary + one secondary term, naturally;
- cover the primary and a few secondaries across the **full description** (the
  first ~167 chars show above the fold and matter most).

Write for humans — Google penalises keyword stuffing and repetition and can
reject the listing. Detail in
[references/metadata-spec.md](references/metadata-spec.md#aso-on-google-play-there-is-no-keywords-field).

### 8. Hand off to `play-store-deliver` (this skill does not upload)
Authoring ends at validation. **Uploading is a separate skill** — once the hub
content is written and the validator is clean, hand off to **`play-store-deliver`**,
the single Play send-surface: it syncs the hub tree down into
`fastlane/metadata/android/`, re-verifies completeness (blocking on any missing
field), and uploads via `fastlane supply` (Google Play Developer API, service-account
key from the hub `DATA.md`). Tell the user that's the next step; don't run `supply`
from here.

The Play-Console-only leftovers (Data safety form, content rating (IARC), pricing &
countries, app-content declarations, creating the app entry) are listed in
[references/metadata-spec.md](references/metadata-spec.md#done-on-the-play-console-website)
and are completed during `play-store-deliver`.

## What's safe to do vs ask first
**Safe:** scaffolding the folder structure, drafting/cleaning field text within
limits, validating, fixing over-limit strings (with the user's wording), resizing
graphics.
**Ask first:** installing fastlane/gems, overwriting existing human-written copy.
(Uploading is `play-store-deliver`'s concern, not this skill's.)

## Reference files
- [references/metadata-spec.md](references/metadata-spec.md) — fields, limits,
  locale codes (incl. the `iw-IL` Hebrew gotcha), graphic specs, ASO guidance,
  fastlane supply setup, and the website-only steps.
- [scripts/scaffold_metadata.py](scripts/scaffold_metadata.py) — create the
  per-locale file tree (non-destructive).
- [scripts/validate_metadata.py](scripts/validate_metadata.py) — validate against
  Google's limits and required fields.

(The hub→repo sync + the `supply` upload now live in the `play-store-deliver` skill.)
