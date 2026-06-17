---
name: app-store-metadata
description: >-
  Create, organize, and validate App Store / Mac App Store metadata for an
  Xcode project using fastlane deliver — localized text (name, subtitle,
  description, keywords, promo text, release notes, URLs), review information,
  categories, and screenshots. Use this whenever the user wants to prepare,
  write, translate, fix, or upload App Store listing text/metadata, set up
  fastlane for metadata, manage multi-language listings, or get screenshots into
  the right App Store sizes. It checks for fastlane and installs it if missing,
  scaffolds the per-locale file structure, validates everything against Apple's
  character limits and required fields, and tells the user exactly which steps
  must be done on the App Store Connect website (things fastlane can't do).
---

# App Store Metadata (fastlane)

Getting an app listing accepted means every localized field is present, within
Apple's character limits, and consistent across languages — and that the things
fastlane *can't* upload (age rating, pricing, privacy questionnaire) get done on
the website. This skill manages the local metadata via fastlane `deliver` and
hands off the rest with clear instructions.

Guide the user — don't just generate files. Listing copy is a product/marketing
decision; ask for the positioning and translate intent faithfully rather than
inventing claims. Confirm before installing tools or uploading.

> **Where the listing copy comes from.** This skill owns the file mechanics —
> scaffolding, field placement, character-limit validation, and the `deliver`
> upload — not necessarily the wording. In the **BD TECH studio flow** the copy is
> lifted from the app's profile (`~/Developer/app-hub/<slug>/profile.md`) by the
> `store-metadata-writer` skill, which drives this one; so when a profile exists,
> take the copy from there (or let `store-metadata-writer` orchestrate) instead of
> re-authoring it here. Standalone (no profile), the app's `README.md` — written and
> owned by the `app-identity` skill — is the source of truth: take the **App name** and
> **Subtitle** from its identity block and base the **description** on its ranked
> feature list, rather than re-authoring. Only if there's no README either, write the
> fields with the user as below. Either way, never fabricate claims.

## Workflow

### 1. Check fastlane
Detect whether fastlane is set up:
- `fastlane/` directory with a `Fastfile` and/or `metadata/`,
- `fastlane` in the `Gemfile`, or `which fastlane` / `bundle exec fastlane`.

If missing, guide installation (ask first — it changes the environment). See
[references/fastlane-setup.md](references/fastlane-setup.md) for the install and
`deliver` init steps. Prefer Bundler (`Gemfile` + `bundle install`) so the
version is pinned.

### 2. Understand the listing shape
- **Platform** — iOS vs macOS. This drives screenshots (iOS supports a capture
  script; macOS does not — see step 5) and the screenshot sizes.
- **One app or several targets** — a single project can ship multiple apps from
  one `fastlane/` folder, each with its own `metadata/<app>/` path and `deliver`
  lane (detect this; don't assume one app).

### 2a. Ask which languages — ALWAYS ask, never assume
Language choice is the user's decision and shapes everything downstream (how
many files, how much copy to write/translate, screenshot locales). So:

1. First detect what already exists — list the locale folders currently under
   `metadata/` so the user sees the starting point.
2. Then ASK explicitly, two things:
   - **Single language or multiple?** Don't default to multi-language — a
     one-locale listing is a legitimate and common choice; more locales means
     more copy to maintain and translate.
   - **Which specific languages?** Have them name the App Store languages they
     want (e.g. English (U.S.), German, Spanish, Hebrew). Offer the ones already
     present as the default to keep, and confirm any to add or remove.
3. Map each chosen language to its App Store locale code (`en-US`, `en-GB`,
   `de-DE`, `es-ES`, `fr-FR`, `ja`, `zh-Hans`, `he`, …). The full list and the
   primary-language rule are in [references/metadata-spec.md](references/metadata-spec.md).

Use the AskUserQuestion tool for this when available — it's exactly the kind of
branching decision (single vs multi, and which set) that the user should drive.
Only proceed to scaffolding once the language set is confirmed.

### 3. Ask: text only, or text + screenshots
This changes the work substantially, so ask up front:
- **Text only** — fastest; just the localized `.txt` fields + review info.
- **Text + screenshots** — also prepare/upload screenshots (step 5).

### 4. Create / update the metadata files
Scaffold the per-locale structure (won't overwrite existing content):
```bash
python3 ~/.claude/skills/app-store-metadata/scripts/scaffold_metadata.py <metadata-root> --locales en-US,de-DE,he
```
Then fill the fields. In the BD TECH studio flow the wording comes from the
profile (via `store-metadata-writer`); standalone, take **App name** / **Subtitle**
from the app's `README.md` (the `app-identity` skill's source of truth) and base the
description on its feature list — or write the base language with the user if
there's no README — then translate to the others, keeping each field within its
limit (the translated string, not the source, must fit). The 100-char **keywords**
field is
an ASO decision owned by the `aso-keywords` skill — this skill just stores and
validates it. Field list, limits, and which files are per-locale vs shared are in
[references/metadata-spec.md](references/metadata-spec.md).

### 5. Screenshots (only if chosen)
Three skills divide this work: for a full, repeatable **capture** (a scripted
XCUITest demo flow producing stills + App Preview videos across locales) hand off
to the `appstore-media` skill; for a one-off **conform** of an existing image to
an exact size use `apple-app-store-screenshots`; this skill then **organizes** the
resulting files under `metadata/` and uploads them via `deliver`.
- **iOS** — you can automate with `fastlane snapshot` (UI-test driven capture
  across devices/locales) and `frameit` for framing. See
  [references/screenshots.md](references/screenshots.md).
- **macOS** — there is NO snapshot automation; screenshots are captured manually
  at the required pixel sizes. Guide the manual capture, then use the
  `apple-app-store-screenshots` skill to conform any image to the exact App
  Store dimensions. Sizes and steps are in
  [references/screenshots.md](references/screenshots.md).

### 6. Validate against Apple's requirements
Always validate before uploading — over-limit fields and missing required files
are the common metadata rejections/errors:
```bash
python3 ~/.claude/skills/app-store-metadata/scripts/validate_metadata.py <project-root-or-metadata-root>
```
It checks character limits, required fields per locale, URL fields, and
cross-locale completeness, and prints a report. Fix every error it flags.

### 7. Upload what fastlane can; hand off the rest
- Upload metadata (and screenshots) with the project's `deliver` lane(s) — see
  [references/fastlane-setup.md](references/fastlane-setup.md). Use
  `--skip_binary_upload` / `skip_screenshots` appropriately; do a
  `--verify_only` / precheck run first.
- Then tell the user exactly what to finish on **App Store Connect** (website),
  because fastlane can't: age rating questionnaire, pricing & availability, the
  App Privacy "nutrition label", export compliance, and creating the app record
  if it doesn't exist. The website-only list is in
  [references/metadata-spec.md](references/metadata-spec.md#done-on-the-app-store-connect-website).

## What's safe to do vs ask first
Safe: scaffolding the folder structure, drafting/cleaning field text within
limits, validating, fixing over-limit strings (with the user's wording).
Ask first: installing fastlane/gems, **uploading** to App Store Connect
(outward-facing and rate-limited), overwriting existing human-written copy, and
anything that publishes to the public listing.

## Reference files
- [references/metadata-spec.md](references/metadata-spec.md) — field list,
  character limits, per-locale vs shared, locale codes, and the website-only
  steps.
- [references/screenshots.md](references/screenshots.md) — iOS snapshot vs macOS
  manual capture, required sizes, and the screenshots skill handoff.
- [references/fastlane-setup.md](references/fastlane-setup.md) — install,
  `deliver` setup, multi-app lanes, and upload commands.
- [scripts/scaffold_metadata.py](scripts/scaffold_metadata.py) — create the
  per-locale file tree (non-destructive).
- [scripts/validate_metadata.py](scripts/validate_metadata.py) — validate
  against Apple's limits and required fields.
