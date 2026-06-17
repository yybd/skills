---
name: ship-apple-app
description: >-
  Verify an Apple app is submission-ready and ship it — the FINAL App Store / Mac
  App Store step: confirm the content is already in place (signing, compliance,
  metadata, screenshots, app record), then archive, upload, complete the App Store
  Connect website steps, and submit. Use this when the user wants to
  release/publish/submit/upload a build, asks "how do I upload or submit to the App
  Store", or is at the end of the process and wants the verify → upload → submit
  checklist. This skill does NOT produce the listing copy, screenshots, compliance
  fixes, or signing — those are owned by their focused skills (app-store-metadata,
  appstore-media, app-store-review-compliance, apple-credentials,
  code-signing-provisioning). It VERIFIES their output is present and valid, then
  builds, uploads, and submits (including the website-only steps fastlane can't do).
---

# Ship an Apple App — verify & submit

This is the **final** step of the App Store / Mac App Store path. By the time you run
it, the content should already exist: signing set up, compliance passed, listing
metadata + screenshots produced, the app record created. **This skill does not
re-produce any of that** — it **verifies** each piece is ready, then **archives →
uploads → finishes on the App Store Connect website → submits**.

If a verification check fails, **hand off to the skill that owns that piece** to
produce it, then come back and re-verify. This skill owns only the ship itself
(build, upload, the website-only steps, submit).

## How to use
1. Detect where the user is: brand-new app or an update? App record already in App
   Store Connect? An update skips the one-time setup checks.
2. Run the **pre-flight verification** below. For anything missing or invalid, hand
   off to the owning skill, then re-verify — don't produce it here.
3. **Build → upload → finish-on-website → submit**, confirming before every
   outward-facing step.

## Pre-flight verification — confirm each is READY (don't produce here)

| Area | Verify it's ready | Owned/produced by |
|------|-------------------|-------------------|
| **App record + bundle ID** | the bundle ID is registered (portal) and the app record exists in App Store Connect | one-time portal/ASC setup |
| **App name & identity** | the on-device display name is set, and the listing **name**/**subtitle** are decided and consistent with it (the README identity block matches the build settings) | `app-identity` (decides the names early + owns the README source of truth) |
| **Signing** | Apple Distribution cert + profile present; MAS build is sandboxed + Hardened Runtime | `apple-credentials` (certs/credentials) · `code-signing-provisioning` (config/errors) |
| **Compliance** | no blockers — run the build-time checklist | `app-store-review-compliance` |
| **Listing metadata** | every locale present and within Apple's limits (run the validator) | `app-store-metadata` (the listing copy may be authored upstream — e.g. from an app profile — this skill only checks it's present & valid) |
| **Screenshots** | exact sizes for every required device class, all locales — for BD TECH apps the source media lives in the hub at `~/Developer/app-hub/<slug>/media/apple/` | `appstore-media` (capture) · `apple-app-store-screenshots` (conform) |
| **In-app localization** | UI fully localized if shipping multi-locale | `localization-i18n` |
| **Design** (optional) | no high-impact accessibility/HIG issues | `apple-hig-design-review` |

**Verify, don't re-produce.** If an item is missing or invalid, hand off to the
owning skill above, then return here.

## Build & archive  [local]
- Bump version/build number (build must be higher than any previously uploaded).
- Archive the App Store target (Xcode: Product → Archive, or `fastlane gym`/`build_app`).

## Upload  [local]
- Upload the binary (Xcode Organizer, Transporter, or `fastlane deliver`/`pilot` for
  TestFlight). Processing takes minutes — wait for it before selecting the build.
- Upload the verified metadata/screenshots via the metadata skill's `deliver` lane if
  not already uploaded (`--verify_only`/precheck first).

## Finish on the App Store Connect website  [website — fastlane can't]
Guide the user through each, with exact navigation:
- Select the uploaded **build** for the version.
- **Age rating** questionnaire · **Pricing & availability** · **App Privacy** nutrition
  label (must match the privacy manifest / real behavior) · **Export compliance** ·
  content rights; any IAPs created & submitted with the version.
- Walkthrough: [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md#7-finish-and-submit).

## Submit
- **Submit for Review** (never auto-submit without the user's explicit go-ahead).
- Choose manual vs automatic release.
- If rejected: read the resolution-center message, map it to a guideline (the
  `app-store-review-compliance` skill helps), fix, and reply/resubmit.

## Boundaries
- You cannot operate the App Store Connect website or the developer portal for the
  user — for every website step, give the exact menu path and what to enter, then wait
  for them to confirm.
- Uploading and submitting are outward-facing and often irreversible — always confirm
  before an upload/submit command or before telling the user to press Submit.

## Reference files
- [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md)
  — navigation-level steps for the portal + App Store Connect website parts.

## Related skills (they produce; this skill verifies + ships)
- `app-identity` — decides the app name/subtitle early and owns the README source of truth (verify the on-device name and listing name/subtitle are set & consistent).
- `apple-credentials` · `code-signing-provisioning` — signing/credentials (verify ready).
- `app-store-review-compliance` — compliance (verify it passes).
- `app-store-metadata` — listing metadata files + `deliver` upload (verify present/valid).
- `appstore-media` · `apple-app-store-screenshots` — screenshots/preview (verify present; for BD TECH apps the source lives in the hub at `~/Developer/app-hub/<slug>/media/apple/`).
- `aso-keywords` — keyword optimization (applied upstream, into the metadata).
- `localization-i18n` — in-app strings (verify complete).
- `notarize-and-distribute` — the parallel path for direct (non-App-Store) Mac
  distribution (Developer ID DMG), instead of upload/submit here.
