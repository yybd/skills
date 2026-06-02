---
name: ship-apple-app
description: >-
  End-to-end playbook for shipping a macOS or iOS app to the App Store / Mac App
  Store — from bundle ID and app record creation, through compliance, design,
  metadata, and screenshots, to archive, upload, and submission. Use this when
  the user wants to release/publish/submit an app to the App Store, asks "how do
  I get my app on the App Store", wants a step-by-step of the whole process, is
  starting a submission and unsure of the order, or wants to know which steps are
  done locally vs on Apple's website. This skill ORCHESTRATES the focused skills
  (app-store-review-compliance, apple-hig-design-review, app-store-metadata) in
  the right order and fills the gaps between them (developer portal + App Store
  Connect website steps).
---

# Ship an Apple App — end-to-end playbook

Releasing an app touches three places: your **code/project** (local), the
**Apple Developer portal** (identifiers, certificates), and **App Store
Connect** (the app record, listing, submission). The order matters, and the
single biggest source of confusion is which step lives where. This skill is the
conductor: it walks the phases, calls the focused skills where they fit, and
makes every website-only step explicit.

It does NOT duplicate the focused skills — when a phase is theirs, hand off to
them. Use this as a checklist you progress through with the user, confirming
each phase before moving on. Adapt to where the user already is (a published app
getting an update skips most of phases 1–2).

## How to use this playbook
1. First, figure out where the user is. Ask (or detect): is this a brand-new app
   or an update? Does the app record already exist in App Store Connect? Is the
   bundle ID registered? Don't restart from phase 1 for an app that's already
   live — jump to the relevant phase.
2. Then move through the phases below in order, doing local work and handing off
   to the focused skills, and pausing at each website step to guide the user
   (you can't click in App Store Connect for them — give exact navigation).
3. Track progress out loud (a short checklist of done/next) so a multi-session
   submission stays oriented.

## Phase 0 — Prerequisites (one-time)
- Apple Developer Program membership (paid) active.
- Xcode signed in with the developer Apple ID.
- Decide distribution: App Store (iOS) / Mac App Store (macOS). (Direct/
  notarized Mac distribution is a different path — not this skill.)

## Phase 1 — Identity: bundle ID, certificates, signing  [portal + local]
- **Bundle ID** — must be registered in the Apple Developer portal (Certificates,
  Identifiers & Profiles → Identifiers) before an app record can use it. One per
  app target. Enable the capabilities the app needs (Sign in with Apple, Push,
  iCloud, etc.) on the identifier.
- **Signing** — let Xcode "Automatically manage signing", or use `fastlane match`
  for team certificate sharing. macOS App Store builds need a Mac App
  Distribution cert + provisioning profile, App Sandbox, and Hardened Runtime.
- Detail and exact navigation: [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md#1-developer-portal-identifiers--signing).

## Phase 2 — Create the app record  [App Store Connect website]
- App Store Connect → My Apps → **+ → New App**. Pick platform, the registered
  bundle ID, primary language, name, SKU.
- `fastlane produce` can create the record via API as an alternative, but the
  identifier setup in phase 1 is still portal work.
- Steps: [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md#2-create-the-app-record).

## Phase 3 — Compliance pass  [local → hand off]
Before investing in listing copy, make sure the app won't be rejected.
**Hand off to the `app-store-review-compliance` skill** for a full audit
(privacy strings, PrivacyInfo.xcprivacy, IAP rules, Sign in with Apple, account
deletion, sandbox/entitlement justification, and app-completeness/demo-mode).
Fix blockers now — they're cheaper to fix before a build than after a rejection.

## Phase 4 — Design pass (optional but recommended)  [local → hand off]
If the app's UI hasn't had a design review, **hand off to the
`apple-hig-design-review` skill** for prioritized accessibility/native-feel
improvements. Optional for shipping, but accessibility issues are the cheapest
quality win and shade into review territory.

## Phase 5 — Metadata & screenshots  [local → hand off]
**Hand off to the `app-store-metadata` skill**: it checks/installs fastlane,
asks which languages (single vs multi) and whether to do text-only or
text+screenshots, scaffolds and fills the localized files, validates against
Apple's limits, and uploads via `deliver`. It also lists the website-only
listing steps.

## Phase 6 — Build, archive, upload  [local]
- Bump version/build number (build must be higher than any previously uploaded).
- Archive the App Store target (Xcode: Product → Archive, or
  `fastlane gym`/`build_app`).
- Upload the binary (Xcode Organizer, Transporter, or `fastlane deliver`/
  `pilot` for TestFlight). Processing takes minutes — wait for it to finish
  before selecting the build in App Store Connect.
- Run the compliance skill's **build-time checklist** before archiving so you
  don't ship a known-rejectable build.

## Phase 7 — Finish the listing on the website  [App Store Connect website]
fastlane can't do these — guide the user through each, with exact navigation:
- Select the uploaded **build** for the version.
- **Age rating** questionnaire.
- **Pricing & availability** (tier, territories).
- **App Privacy** "nutrition label" — must match the privacy manifest / real
  behavior.
- **Export compliance** (encryption) declaration.
- Content rights; any in-app purchases created & submitted with the version.
- Walkthrough: [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md#7-finish-and-submit).

## Phase 8 — Submit & after
- **Submit for Review** (never auto-submit without the user's explicit go-ahead).
- Choose manual vs automatic release.
- If rejected: read the resolution-center message, map it to a guideline (the
  compliance skill helps), fix, and reply/resubmit. Demo-mode/2.1 rejections in
  particular are about making the app reviewable — see the compliance skill's
  worked pattern.

## Boundaries
- You cannot operate the App Store Connect website or the developer portal for
  the user — for every website step, give the exact menu path and what to enter,
  then wait for them to confirm it's done.
- Uploading and submitting are outward-facing and often irreversible (a
  submitted build, a published release) — always confirm before running an
  upload/submit command or telling the user to press Submit.

## Reference files
- [references/appstoreconnect-walkthrough.md](references/appstoreconnect-walkthrough.md)
  — detailed, navigation-level steps for the developer portal and App Store
  Connect website parts (phases 1, 2, 7, 8).

## Related skills (hand off, don't reimplement)
- `app-store-review-compliance` — phase 3 (and build-time checklist in phase 6).
- `apple-hig-design-review` — phase 4.
- `app-store-metadata` — phase 5.
- `apple-app-store-screenshots` — conform screenshots to exact sizes (used by
  the metadata skill in phase 5).
