---
name: notarize-and-distribute
description: >-
  Take a built macOS app from an Xcode archive, package it into a signed DMG,
  notarize it with Apple, staple the ticket, and verify that everything — the
  app AND the DMG — is properly signed and notarized for direct (non-App-Store)
  distribution. Use this whenever the user wants to ship a Mac app outside the
  Mac App Store: build/create a DMG, sign with Developer ID, notarize, staple,
  fix "app is damaged / can't be opened / unidentified developer" Gatekeeper
  errors, or verify notarization status. Covers the Developer ID flow only (for
  Mac App Store builds, that's a different signing path).
---

# Notarize & Distribute (Developer ID DMG)

For a Mac app distributed outside the App Store, Apple's Gatekeeper will block it
unless it is signed with **Developer ID**, **notarized** by Apple, and the
notarization ticket is **stapled**. Miss any step and users see "app is damaged"
or "unidentified developer". This skill runs the whole chain — locate the app →
DMG → sign → notarize → staple → verify — and checks that the DMG *and* the app
inside it pass Gatekeeper.

The work is automatable (codesign/hdiutil/notarytool/stapler are all CLI), so
this skill mostly *does* rather than guides — via
[scripts/notarize_dmg.py](scripts/notarize_dmg.py). The only manual prerequisite
is one-time credential setup.

## Prerequisites (check first, and guide the user if missing)

### A) A Developer ID Application certificate
Run `list` (see step 2). If **no "Developer ID Application"** identity is found,
don't just error — get one created, then continue:
- **If the `apple-credentials` skill is available, hand off to it** — it owns
  certificates: it explains the types, why this flow needs *Developer ID
  Application* specifically, and guides creation/`.p12` export. Come back here
  once the cert exists.
- **If that skill is NOT installed, guide the user inline through Xcode** and
  continue once done:
  1. Xcode → Settings (⌘,) → **Accounts** → select the Apple ID →
     **Manage Certificates…**
  2. Click **+** → **Developer ID Application** (Xcode creates the key + cert and
     installs them in the login keychain).
  3. Re-run `list` to confirm it now appears, then proceed.
  Briefly tell the user *why*: Gatekeeper only trusts directly-distributed apps
  signed by a Developer ID identity — an Apple Development or Apple Distribution
  cert will be rejected by notarization, so it must be this specific type.

### B) A notary credential
Run `list`; if **no notary profile** is detected, set one up:
- **Prefer the `apple-credentials` skill** — it owns auth credentials
  (app-specific passwords, notary profiles, API keys). Hand off to it to create
  the notary profile (from an app-specific password or an API key), then come
  back with the profile name.
- **Fallback if that skill isn't installed** — this skill's own `store-creds`
  does the same for the password case: explain the user needs an app-specific
  password (account.apple.com → Sign-In & Security → App-Specific Passwords;
  `setup` prints the steps), collect it + Apple ID + team + a profile name, then:
  ```bash
  NOTARY_PASSWORD='abcd-efgh-ijkl-mnop' \
    python3 .../notarize_dmg.py store-creds --profile "TabBarNotary" \
    --apple-id "you@example.com" --team-id "ABCDE12345"
  ```
  Afterward the user has a reusable profile (`--keychain-profile TabBarNotary`),
  no password needed again. The password is the user's secret — only they
  generate it; the skill turns it into a stored, reusable profile.

### C) Build settings
The app must be built with **Hardened Runtime ON** and signed with a secure
**timestamp** — notarization rejects apps without these.

## Workflow

### 1. Locate the app and check its signing
```bash
python3 .../notarize_dmg.py locate <path-to.xcarchive | export-dir | App.app>
```
It finds the `.app` (in an `.xcarchive` it looks in `Products/Applications/`) and
reports whether it's signed with Developer ID, has Hardened Runtime, and has a
secure timestamp. Resolve any ⚠️ before continuing — an app that isn't
Developer-ID/hardened/timestamped will fail notarization. The cleanest source is
an archive exported with the **Developer ID** method (Xcode Organizer →
Distribute App → Developer ID), which produces a correctly signed `.app`.

### 2. Choose the signing identity — ask, don't auto-pick
The skill must NOT silently use whatever certificate it finds. First list what's
available, then confirm with the user which to use:
```bash
python3 .../notarize_dmg.py list
```
This prints the Developer ID Application identities in the keychain (and any
detectable notary profiles). When more than the empty case exists, ASK the user
which identity to use (AskUserQuestion is ideal — one option per identity), then
pass the chosen one as `--identity "Developer ID Application: …"`. If exactly one
is found, still confirm it ("Use this certificate: …?") rather than assuming.
The script enforces this: `build` without `--identity` prints the choices and
stops (exit 3) instead of auto-selecting; `--yes` is an explicit opt-in to use
the first (e.g. CI), only when the user has authorized that.

### 3. Build and sign the DMG (local, safe)
```bash
python3 .../notarize_dmg.py build --app <App.app or .xcarchive> --out dist/ \
    --identity "Developer ID Application: …" [--versioned]
```
It re-checks app signing, builds a compressed DMG (with an `/Applications`
symlink for drag-install) via `hdiutil`, and signs the DMG with the chosen
Developer ID identity + timestamp. Use `--sign-app` only if you need it to
(re)sign the app itself; prefer a properly-exported archive.

### 4. Notarize and staple (network — confirm with the user first)
This step talks to Apple and is outward-facing, so confirm before running. Also
confirm WHICH notary credential to use: run `list` to show detected profiles and
ask the user which profile (or API key) to notarize with — don't assume a
default. Then:
```bash
python3 .../notarize_dmg.py notarize --dmg dist/App.dmg --keychain-profile <chosen-profile>
```
It submits with `notarytool submit --wait`, prints the result, and on success
staples the ticket to the DMG. On failure it fetches the notary **log** so you
can see exactly which binary/issue caused it (common causes in
[references/notarization.md](references/notarization.md)).

### 5. Verify everything (app + DMG)
```bash
python3 .../notarize_dmg.py verify --dmg dist/App.dmg --app <App.app>
```
Confirms: code signature valid (`codesign --verify --deep --strict`), Gatekeeper
accepts both the app (`spctl -t exec`) and the DMG
(`spctl -t open`), and the notarization ticket is stapled (`stapler validate`).
A green run here means a user can download the DMG and open the app cleanly.

## Stapling note (app vs DMG)
Stapling the DMG is enough for DMG download+open. For maximum robustness (the app
still validates offline after being dragged out), staple the `.app` too: notarize
a zip of the app, `stapler staple App.app`, then build the DMG from the stapled
app. The reference explains when this matters; for most DMG distribution,
stapling the DMG is sufficient.

## Safety
- The `notarize` step is the only network/outward-facing one — always confirm
  before running it. The rest is local and reversible.
- Don't fabricate "notarized" status: only report success when `verify` actually
  passes `spctl` + `stapler`.

## What's next (out of scope here)
Hosting/updates (uploading the DMG to a CDN/R2, generating a Sparkle appcast for
auto-updates) is a separate concern — note it if the user mentions it, but this
skill ends at a verified, notarized, stapled DMG.

## Reference files
- [references/notarization.md](references/notarization.md) — the Developer ID +
  notarization model, credential setup, common notary-log failures and fixes,
  and the verification commands explained.
- [scripts/notarize_dmg.py](scripts/notarize_dmg.py) — locate / build / notarize
  / verify / setup.
