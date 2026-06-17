# App Skills Family — Guide

A guide to the skills built for developing and shipping apps — most target
macOS/iOS (App Store and direct distribution), plus a sibling for Google Play.
What each one does, who owns what, the dependencies between them, and usage
examples.

Updated: 2026-06-17 · Skills location: `~/.claude/skills/` · **16 skills**

> **BD TECH studio flow:** the 16 skills here are **generic mechanics** (Apple/Google knowledge) and
> work in any project. Inside BD TECH they are driven by the Hub layer: the source of truth for all
> copy is the app's profile (`<slug>/profile.md`), copy is **lifted** from it (never invented), and
> media (`appstore-media`) is written into the Hub. For the end-to-end orchestration
> (profile → media → stores → site → ship), the Hub layer, and where each skill runs, see
> `~/Developer/app-hub/APP-LIFECYCLE.md` (the studio hub).

---

## Overview — the 16 skills (by role)

**Orchestrator**

| Skill | One-liner |
|-------|-----------|
| **ship-apple-app** | Playbook that orchestrates the whole App Store path: from bundle ID to submit |

**Identity & signing**

| Skill | One-liner |
|-------|-----------|
| **apple-credentials** | Single owner of certificates + credentials (creation, `.p12`, notary, API key) |
| **code-signing-provisioning** | Signing model, provisioning profiles, diagnosis, decoding errors |

**Quality, compliance & localization**

| Skill | One-liner |
|-------|-----------|
| **app-store-review-compliance** | Conformance to Apple's Review Guidelines (prevents rejections) + reviewer demo mode |
| **apple-bug-flow-review** | Functional QA: finds logic/code bugs + broken user flows (static scan + analyzer + sanitizers + XCUITest) |
| **apple-hig-design-review** | Design/accessibility review vs the HIG (prioritized recommendations) |
| **localization-i18n** | In-app localization: strings, hardcoded text, translation completeness, RTL |

**Name & identity (source of truth)**

| Skill | One-liner |
|-------|-----------|
| **app-identity** | Decides the app's name (on-device display + App Store + subtitle) in discussion with the developer (never alone), writes the display name into build/Info.plist, and owns the README as the source of truth (identity + ranked feature list). Runs **early** — before metadata/media |

**Listing & assets (App Store)**

| Skill | One-liner |
|-------|-----------|
| **app-store-metadata** | Owns the listing files: multi-language text + screenshot files, validation, upload via `deliver` |
| **appstore-media** | Produce screenshots + App Preview videos from an XCUITest demo flow |
| **apple-app-store-screenshots** | Conform a single existing image to exact pixel dimensions |
| **app-icon-generator** | Generate an AppIcon set for all platforms from one image |
| **aso-keywords** | Optimize the name/subtitle/keywords for search discoverability |

**Direct distribution (macOS, outside the App Store)**

| Skill | One-liner |
|-------|-----------|
| **notarize-and-distribute** | DMG → Developer ID signing → notarization → staple → verify |

**Post-launch**

| Skill | One-liner |
|-------|-----------|
| **app-store-reviews-responder** | Monitor user reviews and draft responses |

**Android (sibling skill)**

| Skill | One-liner |
|-------|-----------|
| **play-store-metadata** | Google Play metadata via fastlane `supply` — the counterpart of `app-store-metadata` |

---

## Who owns what (single source of truth)

Principle: each topic belongs to ONE skill; the others **draw** from it (and if
it isn't installed, fall back to a local minimal version — usually Xcode-based
guidance).

| Topic | Owner | Who draws / feeds |
|-------|-------|-------------------|
| **On-device display name** (PRODUCT_NAME/CFBundleDisplayName) + **deciding** the store name/subtitle + **README source of truth** (identity + ranked feature list) | **app-identity** | app-store-metadata, aso-keywords, appstore-media, and app-profile (Hub) draw from the README; runs early, before metadata/media |
| Certificates, creation, `.p12`, app-specific password, notary profile, API key | **apple-credentials** | code-signing, notarize-and-distribute, ship-apple-app, app-store-metadata, app-store-reviews-responder |
| Signing model, provisioning profiles, signing errors, diagnosis | **code-signing-provisioning** | ship-apple-app |
| Review rules + reviewer demo mode + privacy manifest + justified entitlements | **app-store-review-compliance** | ship-apple-app, appstore-media (to distinguish the two demo modes) |
| Correctness/robustness bugs + user-flow QA (does it work?) | **apple-bug-flow-review** | ship-apple-app (optional, pre-archive); reuses appstore-media's demo mode + a11y IDs for smoke flows |
| Design/accessibility (HIG) | **apple-hig-design-review** | ship-apple-app (optional) |
| In-app localization (strings, translation, RTL) | **localization-i18n** | ship-apple-app (before metadata) |
| App Store listing files (text + screenshot files) + upload via `deliver` | **app-store-metadata** | ship-apple-app; **fed by** appstore-media, apple-app-store-screenshots, aso-keywords |
| **Producing** screenshots + videos (demo-flow) | **appstore-media** | reads the profile; writes media to `<slug>/media/apple/` in the Hub (via `-o`); feeds app-store-metadata |
| **Conforming** a single existing image to size | **apple-app-store-screenshots** | used by app-store-metadata, appstore-media |
| Keywords / ASO (Apple) | **aso-keywords** | reads & feeds app-store-metadata |
| Icons | **app-icon-generator** | standalone (used in ship phase 5) |
| Direct distribution (DMG/notarize) | **notarize-and-distribute** | draws from apple-credentials |
| User reviews + responses | **app-store-reviews-responder** | draws from apple-credentials (API key) |
| Google Play listing (Android) | **play-store-metadata** | parallel sibling of app-store-metadata |

### The screenshot trio (the most important distinction)
Three skills touch screenshots — don't confuse them:
- **appstore-media** = **produce** (capture from the running app via an XCUITest demo flow; also App Preview videos).
- **apple-app-store-screenshots** = **conform** (one image that already exists → exact pixel size).
- **app-store-metadata** = **organize/upload** (place files into `metadata/`, validate limits, `deliver`).

### The quality trio (don't confuse the three "review" skills)
Three skills review the app before shipping, each a different question:
- **apple-bug-flow-review** = **does it work / is it correct?** (crashes, races, leaks, data loss, broken user flows — functional QA).
- **app-store-review-compliance** = **will Apple accept it?** (Review-Guideline rules — privacy strings, IAP, demo mode, entitlements).
- **apple-hig-design-review** = **does it feel native & accessible?** (design/UX/accessibility polish vs the HIG).

Overlaps resolve by ownership: a flow-blocking UX bug is bug-flow's; aesthetic polish is HIG's; a rejection rule is compliance's; a security vuln defers to the `security-review` skill.

### The studio layer (Hub) — where the copy comes from
In the **BD TECH studio flow** the store workers are driven by the Hub layer, and the source of copy is the profile — never invented:
- `app-identity` `[any project]` → the repo's `README.md` = the source of truth for identity (display/store name, subtitle) and the ranked feature list. Runs **before** `app-profile`.
- `app-profile` `[Hub]` → `<slug>/profile.md` = the source of truth for all copy; **draws from `app-identity`'s README** (names + feature ranking), then enriches with code + market research.
- `store-metadata-writer` `[Hub]` → lifts the copy from the profile and runs `app-store-metadata` /
  `play-store-metadata` / `aso-keywords` (they own the files / validation / ASO — **not** copy authorship).
- `add-app-to-site` `[bd-tech]` → the website.
- `appstore-media` → reads the profile and writes media to `<slug>/media/apple/` in the Hub.

**Rule:** when a profile exists, don't author store copy from scratch in the workers — lift it from
the profile (or let `store-metadata-writer` orchestrate). Standalone (no profile), the workers write
with the user as usual. Full detail: `APP-LIFECYCLE.md`.

---

## Dependency map

```
                          ┌─────────────────┐
                          │  ship-apple-app │  (orchestrates the App Store path)
                          └────────┬────────┘
   ┌───────────┬───────────┬───────┼────────┬───────────────┬─────────────┐
   ▼           ▼           ▼       ▼        ▼               ▼             ▼
apple-creds  code-sign  compliance hig  localization-i18n  app-store-metadata
   ▲           │                                                ▲   ▲   ▲
   │           │ (draws certs)                                  │   │   │
   └───────────┘                          appstore-media ───────┘   │   │
   ▲                                       apple-app-store-screenshots┘   │
   │ (draws certs + notary)                aso-keywords ─────────────────┘
notarize-and-distribute   ← separate path: direct distribution (DMG), not App Store
app-store-reviews-responder ← post-launch (draws API key from apple-credentials)
app-icon-generator   ← standalone, no dependencies
```

**Source of truth — `app-identity` decides the name and writes the README; the listing/media skills draw from it:**

```
app-identity  ─▶  README.md  ─┬─▶  aso-keywords        (name/subtitle → keywords)
(runs early — (identity +  ├─▶  app-store-metadata   (name / subtitle / description)
 before        ranked       ├─▶  appstore-media       (screen story / captions)
 metadata)     features)    └─▶  app-profile [Hub] ─▶ profile.md ─▶ store-metadata-writer
play-store-metadata  ← parallel to app-store-metadata; cross-platform, draws from the same README
```

Fallback principle: if a drawing skill can't find the owner (e.g.
`apple-credentials` isn't installed), it performs a minimal local version itself
and continues.

---

## The main journeys

### Path A — App Store / Mac App Store
```
ship-apple-app orchestrates:
1. Identity      → apple-credentials (Apple Distribution) + code-signing-provisioning
2. App record    → App Store Connect (website)
3. Compliance    → app-store-review-compliance
4. Design        → apple-hig-design-review (optional)
5. Localization  → localization-i18n (if the UI isn't fully translated)
6. Name+assets+listing → app-identity (display name in build/Info.plist + decide store name/subtitle + README source of truth)
                   → aso-keywords (keywords) → appstore-media (produce screenshots/videos)
                   → apple-app-store-screenshots (conform a single image) → app-store-metadata
                   (organize+validate+deliver) → app-icon-generator (icon)
7. build / archive / upload
8. Finish on site → age rating, pricing, App Privacy
9. submit
```

### Path B — Direct distribution (DMG, outside the App Store, macOS only)
```
1. Certificate   → apple-credentials (Developer ID Application)
2. Credential    → apple-credentials (notary profile from app-specific password)
3. package + sign + notarize + staple + verify → notarize-and-distribute
```

### Path C — Google Play (Android)
```
play-store-metadata: scaffold → fill multi-language text + graphics → validate →
fastlane supply (upload) → finish on Play Console (Data safety, content rating, pricing)
```

---

## Usage examples (phrases that trigger each skill)

**ship-apple-app** — "How do I get my app on the App Store from scratch?" · "Walk me through the whole submission step by step"

**apple-credentials** — "Which certificate do I need to upload to the App Store?" · "Check which certificates I have" · "Export the certificate as `.p12` for GitHub Actions" · "Set up a notary profile"

**code-signing-provisioning** — "I got 'Provisioning profile doesn't include signing certificate' — what now?" · "Diagnose my project's signing"

**app-store-review-compliance** — "Why did Apple reject the app? Guideline 2.1" · "Check the project against the Review Guidelines before I submit"

**apple-bug-flow-review** — "Find bugs before I ship" · "Do a QA pass on the app" · "Why does it crash / lose my data / freeze?" · "Check that the user flows actually work" · "בדוק באגים" · "בדיקת זרימת המשתמש"

**apple-hig-design-review** — "Do a design review — does the UI feel native?" · "Check accessibility (VoiceOver / Dynamic Type)"

**localization-i18n** — "Add Hebrew support to the app" · "Find hardcoded un-localized strings" · "Are all locales complete?"

**app-identity** — "What should I call the app?" · "Change the name shown under the icon / in the menu bar" · "Update the App Store name and subtitle" · "Write/refresh the README and feature list"

**app-store-metadata** — "Prepare App Store metadata in Hebrew and English" · "Validate everything is within the character limits"

**appstore-media** — "Prepare App Store screenshots" · "I need an App Preview video" · "A demo flow that produces screenshots in every locale"

**apple-app-store-screenshots** — "Make this image the right App Store size" · "Apple rejected my screenshot — fix the size"

**app-icon-generator** — "Generate the icon in all sizes from this image" · "I have no icon — make a starter one"

**aso-keywords** — "Improve my search ranking" · "Audit my keywords field"

**notarize-and-distribute** — "Build a DMG, sign it, and notarize" · "Users get 'app is damaged' — fix it"

**app-store-reviews-responder** — "Show me recent reviews" · "Draft a reply to this negative review"

**play-store-metadata** — "Prepare a Google Play listing" · "Set up fastlane supply" · "Translate the Play description to Hebrew and English"

---

## End-to-end scenarios

### "I submitted to Apple and got rejected on 2.1 (demo mode)"
→ `app-store-review-compliance` diagnoses the missing reviewer demo path, fixes/
drafts a demo mode + review notes. (Note: this is the **reviewer** demo mode, not
the marketing-capture demo mode in `appstore-media` used for screenshots.)

### "I need screenshots and a video for the App Store page"
→ `appstore-media` (produce from a demo flow, in every locale) → `app-store-metadata`
(organize and upload). For a single image that just needs resizing:
`apple-app-store-screenshots`.

### "I want to ship a new DMG release"
→ `apple-credentials` (Developer ID + notary profile) → `notarize-and-distribute`.

### "Starting a brand-new app"
→ `ship-apple-app` as the playbook, orchestrating: `apple-credentials` →
`app-icon-generator` → `app-store-review-compliance` → `localization-i18n` →
`app-store-metadata` (+ `appstore-media` / `aso-keywords`) → build → submit.

### "I'm shipping the same app to Android too"
→ In BD TECH: `store-metadata-writer` coordinates both stores from one profile (consistent across
App Store and Play) and runs `app-store-metadata` and `play-store-metadata`. Standalone (no profile):
run both — write the base copy once and adapt per store (Play has no keywords field — discoverability
lives in the visible text).

---

## Planned skills (roadmap)

Skills not yet built — planned future additions:

**Distribution & build**
- **app-hosting-updates** — upload the DMG to R2/CDN + a Sparkle appcast for
  auto-updates (the continuation of `notarize-and-distribute`).
- **storekit-iap** — set up IAP products, StoreKit config, sandbox testing, Restore.
- **testflight-beta** — upload to TestFlight, manage testers, beta notes.
- **release-notes-versioning** — auto build/version bump + multi-language
  "What's New" from git history.
- **ci-cd-apple** — GitHub Actions / Xcode Cloud for build+test+sign+notarize.
- **swift-deprecation-migrator** — Swift 6 concurrency, min-OS bumps, deprecated APIs.

## Notes

- **Activation:** skills load automatically based on context (their description).
  You can also request one explicitly ("use skill X").
- **Location:** `~/.claude/skills/<name>/` — global, available in every project.
- **`.skill` files:** packaged copies for sharing/installation live in the
  project directory (`~/Developer/xcode/OfficeTabsApps/*.skill`).
- **Platforms:** most skills target macOS + iOS; `play-store-metadata` is for
  Android/Google Play; direct distribution (DMG) is macOS-only.
- **Safety:** every outward-facing action (upload, notarization, store-creds,
  fastlane match) requires confirmation before running.
