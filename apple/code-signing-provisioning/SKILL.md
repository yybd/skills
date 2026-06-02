---
name: code-signing-provisioning
description: >-
  Understand, diagnose, and fix Apple code signing and provisioning for macOS
  and iOS Xcode projects — certificates, identifiers, provisioning profiles,
  entitlements, automatic vs manual signing, and fastlane match. Use this
  whenever the user hits a signing/provisioning error ("no signing certificate",
  "provisioning profile doesn't include signing certificate", "doesn't match the
  entitlements", "no profiles found", "failed to register bundle identifier"),
  asks which certificate they need or why, is setting up signing for a new app /
  machine / CI, or needs to diagnose a project's signing configuration. It
  explains the signing model, diagnoses the current setup (build settings,
  provisioning profiles, identities), and decodes errors. For certificate types,
  creating certificates, .p12 export, and auth credentials (app-specific
  passwords / API keys), it defers to the `apple-credentials` skill.
---

# Code Signing & Provisioning

Signing is the most confusing part of Apple development because several
certificates look alike but do different jobs, and the error messages are
cryptic. This skill has two goals: **make the user understand the model** (so
they're not cargo-culting), and **diagnose + fix** the concrete setup.

Teach as you go. When you explain a fix, also explain *why* the right
certificate/profile is required — the user has said they want to understand the
whole process, not just paste commands.

## Start here: understand, then diagnose

### 1. Ground the user in the model (briefly, in their terms)
Before touching errors, make sure the user knows the four moving parts and how
they bind together — certificate, identifier (App ID), entitlements,
provisioning profile — and which **certificate type** matches their goal. The
full, plain-language explanation (the "why each one exists" table and the
platform matrix) is owned by the **`apple-credentials`** skill
(its `certificate-types.md`) — defer there for certificate types/creation. If
that skill isn't installed, give the summary inline yourself.

The one-line version of the binding: a **provisioning profile** ties together a
**certificate** (who signs), an **App ID** (which app + capabilities), and (for
development/ad-hoc) **devices** — and the app's **entitlements** must be a subset
of what the profile/App ID allow. Mismatch anywhere → a signing error.

### 2. Diagnose the current setup
Run the diagnostic to see everything at once instead of guessing:
```bash
python3 ~/.claude/skills/code-signing-provisioning/scripts/diagnose_signing.py <project-root>
```
It reports: the target's signing build settings (automatic vs manual, team,
identity, profile specifier), the signing identities in the keychain (grouped by
type), installed provisioning profiles decoded (name, team, App ID, dev vs
distribution, **expiry**, certificates), and cross-checks (team consistency,
expired profiles, entitlements vs profile). Read it before concluding anything.

### 3. Map the goal to the right certificate
Pick the type for the goal (full table in the `apple-credentials` skill):
- Run/debug on your devices → **Apple Development**
- App Store / Mac App Store → **Apple Distribution** (+ **Mac Installer
  Distribution** for the MAS `.pkg`)
- Direct Mac distribution (DMG/notarized) → **Developer ID Application** (+
  **Developer ID Installer** if shipping a `.pkg`)

### 4. Fix or create what's missing
- If it's an **error**, decode it with
  [references/error-decoder.md](references/error-decoder.md) (symptom → cause →
  fix) and apply the fix.
- If a **certificate is missing**, guide creation (see "Creating a certificate"
  below). Don't try to mint certs silently — creation is tied to the user's
  Apple account and keychain.
- For **teams/CI/multiple machines**, prefer `fastlane match` (shared, version-
  controlled certs/profiles) — see
  [references/fastlane-match.md](references/fastlane-match.md).

## Creating a certificate
Certificate creation (and `.p12` export, limits, roles) is owned by the
**`apple-credentials`** skill — **hand off to it**. If it isn't installed, guide
inline and continue:
1. Xcode → Settings (⌘,) → **Accounts** → select the Apple ID → **Manage
   Certificates…** → **+** → the type needed (Apple Development / Apple
   Distribution / Developer ID Application / Developer ID Installer). Xcode makes
   the key + cert and installs them. (With Automatically manage signing, App
   Store/development certs are created on demand at archive/run.)
2. Portal route when Xcode can't: developer.apple.com → Certificates → + → type
   → upload a CSR → download → double-click to install.
After creation, re-run the diagnostic to confirm the identity appears, then
continue with the original task.

## What's safe vs ask-first
Safe: reading build settings, decoding profiles, diagnosing, explaining,
generating a `Matchfile`/lane. Ask first: running `fastlane match` (touches the
keychain + a private git repo + the Apple account), changing a target's signing
style or team, revoking certificates, or deleting profiles.

## Reference files
- Certificate types, creation, `.p12` export, limits/roles → owned by the
  **`apple-credentials`** skill (its `certificate-types.md`). Defer there.
- [references/error-decoder.md](references/error-decoder.md) — common signing
  errors → cause → fix.
- [references/fastlane-match.md](references/fastlane-match.md) — shared signing
  for teams/CI.
- [scripts/diagnose_signing.py](scripts/diagnose_signing.py) — one-shot signing
  diagnostic.
