# Apple Skills Family — Guide

A guide to the skills built for developing and shipping macOS/iOS apps — what
each one does, who owns what, the dependencies between them, and usage examples.

Updated: 2026-06-03 · Skills location: `~/.claude/skills/`

---

## Overview — the 8 skills

| Skill | One-liner | Type |
|-------|-----------|------|
| **ship-apple-app** | Orchestrating playbook: from bundle ID to App Store submit | Orchestrator |
| **apple-credentials** | Single owner of certificates + credentials (creation, .p12, notary, API key) | Owner |
| **code-signing-provisioning** | Signing model, profiles, diagnosis, decoding signing errors | Diagnostics |
| **app-store-review-compliance** | Conformance to Apple's Review Guidelines (prevents rejections) | Check + fix |
| **apple-hig-design-review** | Design/accessibility review vs the HIG (prioritized recommendations) | Advisory |
| **app-store-metadata** | Multi-language metadata via fastlane + validation against Apple's rules | Build + check |
| **app-icon-generator** | Generate an AppIcon set for all platforms from one image | Generation |
| **localization-i18n** | In-app localization: strings, hardcoded text, translation completeness, RTL | Check + fix |
| **notarize-and-distribute** | Direct distribution: DMG → sign → notarize → verify | Execution |
| **app-store-reviews-responder** | Monitor user reviews and draft responses | Post-launch |
| **aso-keywords** | Keyword optimization (ASO) for search discoverability | Post-launch |

---

## Who owns what (single source of truth)

Principle: each topic belongs to ONE skill; the others **draw** from it (and if
it isn't installed, fall back to a local minimal version).

| Topic | Owner | Who draws from it |
|-------|-------|-------------------|
| Certificates, creation, `.p12`, app-specific password, notary profile, API key | **apple-credentials** | code-signing, notarize-and-distribute, ship-apple-app, app-store-metadata |
| Signing model, provisioning profiles, signing errors, diagnosis | **code-signing-provisioning** | ship-apple-app |
| Review rules + demo mode + privacy manifest + justified entitlements | **app-store-review-compliance** | ship-apple-app |
| Metadata + screenshots (sizing) | **app-store-metadata** | ship-apple-app |
| Screenshot resizing | **apple-app-store-screenshots** (built-in) | app-store-metadata |
| In-app localization (strings, translation, RTL) | **localization-i18n** | — |
| Icons | **app-icon-generator** | — |
| User reviews + responses | **app-store-reviews-responder** | — |
| Keywords / ASO | **aso-keywords** | (reads from app-store-metadata) |
| Design/accessibility | **apple-hig-design-review** | ship-apple-app (optional) |

---

## Dependency map

```
                          ┌─────────────────┐
                          │  ship-apple-app │  (orchestrates the App Store path)
                          └────────┬────────┘
        ┌──────────────┬───────────┼───────────┬──────────────┐
        ▼              ▼           ▼            ▼              ▼
 apple-credentials  code-signing  compliance  hig-review   app-store-metadata
        ▲              │                                        │
        │              │ (draws certs)                          ▼
        └──────────────┘                              apple-app-store-screenshots
        ▲
        │ (draws certs + notary)
 notarize-and-distribute   ← separate path: direct distribution (DMG), not App Store

 app-icon-generator   ← standalone, no dependencies
```

Fallback principle: if a drawing skill can't find the owner (e.g.
`apple-credentials` isn't installed), it performs a minimal local version itself
(usually Xcode-based guidance) and continues.

---

## The two main journeys

### Path A — App Store / Mac App Store
```
ship-apple-app orchestrates:
1. Identity      → apple-credentials (Apple Distribution) + code-signing-provisioning
2. App record    → App Store Connect (website)
3. Compliance    → app-store-review-compliance
4. Design        → apple-hig-design-review (optional)
5. Metadata      → app-store-metadata (+ app-icon-generator for the icon)
6. build / archive / upload
7. Finish on site → age rating, pricing, App Privacy
8. submit
```

### Path B — Direct distribution (DMG, outside the App Store)
```
1. Certificate   → apple-credentials (Developer ID Application)
2. Credential    → apple-credentials (notary profile from app-specific password)
3. package + sign + notarize + staple + verify → notarize-and-distribute
```

---

## Usage examples (phrases that trigger each skill)

**ship-apple-app**
- "How do I get my app on the App Store from scratch?"
- "Walk me through the whole submission process step by step"

**apple-credentials**
- "Which certificate do I need to upload to the App Store?"
- "Check which certificates and credentials I have"
- "I need to export the certificate as `.p12` for GitHub Actions"
- "Set up a notary profile from an app-specific password"

**code-signing-provisioning**
- "I got 'Provisioning profile doesn't include signing certificate' — what now?"
- "Diagnose the signing settings in my project"

**app-store-review-compliance**
- "Why did Apple reject the app? Guideline 2.1"
- "Check the project against the Review Guidelines before I submit"

**apple-hig-design-review**
- "Do a design review — does the UI feel native?"
- "Check accessibility (VoiceOver / Dynamic Type)"

**app-store-metadata**
- "Prepare App Store metadata in Hebrew and English"
- "Validate that all the text is within Apple's character limits"

**app-icon-generator**
- "Generate the app icon in all sizes from this image"
- "I have no icon — create a starter one"

**notarize-and-distribute**
- "Build a DMG, sign it, and notarize"
- "Users get 'app is damaged' — fix it"

---

## End-to-end scenarios

### "I submitted to Apple and got rejected on 2.1 (demo mode)"
→ `app-store-review-compliance` diagnoses the missing demo path, fixes/drafts a
demo mode + review notes. (The real scenario we started from.)

### "I want to ship a new DMG release"
→ `apple-credentials` (confirm Developer ID + notary profile) →
`notarize-and-distribute` (build → sign → notarize → verify).

### "Starting a brand-new app"
→ `ship-apple-app` as the playbook, orchestrating: `apple-credentials` (identity)
→ `app-icon-generator` (icon) → `app-store-review-compliance` (compliance) →
`app-store-metadata` (listing) → build → submit.

---

## Planned skills (roadmap)

Skills not yet built — planned future additions to the family:

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
- **Platforms:** everything supports macOS + iOS; direct distribution (DMG) is
  macOS-only.
- **Safety:** every outward-facing action (upload, notarization, store-creds,
  fastlane match) requires confirmation before running.
