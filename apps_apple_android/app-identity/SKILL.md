---
name: app-identity
description: >-
  Decide and set an Apple app's NAME across every surface, and own the project
  README as the standalone source of truth — including auto-detecting the app's
  feature list (and any Pro/premium IAP tier) from the code and writing it, with
  the chosen names, into the README in a fixed format. Run it when the app is
  feature-complete (at the end of building it) so the README's detected feature
  list reflects the finished software — and in any case BEFORE app-store-metadata,
  aso-keywords, and appstore-media, because everything downstream reads the name,
  subtitle, and feature list from here. Use this whenever the user wants to name
  or rename their app, asks "what should I call my app", wants to change the name
  shown under the icon / in the window title / in the menu bar
  (CFBundleDisplayName / PRODUCT_NAME), change the App Store listing name or
  subtitle, or write/refresh the app's README, detect and document the app's
  features, or build the feature list at the end of development. The skill SCANS
  the code to detect what the app does, its full feature list, and its
  monetization (free / paid / Pro IAP), proposes ASO-aware name + subtitle
  candidates (drawing on the aso-keywords skill), and DISCUSSES them with the
  developer — it never picks a name on its own. Once the developer decides, it
  writes the on-device display name into the Xcode build settings / Info.plist,
  and writes the App name, App Store name, Subtitle, Platform, Bundle id,
  Built-with, any Pro/IAP tier, and the detected ranked feature list into the
  project README (a fixed identity-block format) so app-store-metadata (files),
  aso-keywords (keyword field), and appstore-media (screen story) all draw from
  one place. Distinct from app-store-metadata (which owns the fastlane metadata
  files) and aso-keywords (which owns the 100-char keyword field) — this skill
  decides the name itself and owns the README it lives in.
---

# App Name & README (the app's identity, source of truth)

An app's name is not one string — it shows up under the icon, in the window
title and menu bar, on the App Store listing, and in the subtitle right beneath
it. These have different rules (the on-device display name is an Xcode build
setting; the App Store name and subtitle are fastlane metadata fields with
character limits and ASO weight). When they drift apart, or when nobody wrote
down *why* this name was chosen, every later step re-litigates it.

Run this when the app is **feature-complete** — at the end of building it, and
before the store/listing steps. It decides the name *with the developer*, applies
the on-device part, **detects the app's feature list (and any Pro/premium tier)
from the finished code**, and records all of it in **one source of truth — the
project README** — so the listing/media skills lift from there instead of
re-interviewing or inventing. In the studio (BD TECH) flow that source of truth
is `~/Developer/app-hub/<slug>/profile.md`; for a standalone project it is the
repo's own `README.md`, and this skill owns it.

**The README is the only listing artifact that stays in the app repo.** Everything
else — the per-locale store metadata, the screenshots, and the release notes — lives
in the **hub** (`~/Developer/app-hub/<slug>/store/` + `media/`, owned by
`store-metadata-writer`) and is synced into `fastlane/` only at deliver time. So the
repo holds the **identity** (app name + feature list, here); the hub holds the
**listing**. Keep this README accurate and it stays the one thing a developer reads
or edits in the repo to know what the app is.

## Where this sits in the flow

```
app-identity  ─▶  aso-keywords      (optimize the chosen name/subtitle for search)
   │      ─▶  app-store-metadata (write name.txt / subtitle.txt / description)
   └──────▶  appstore-media     (lift the ranked feature list → screen story)
```

Run it once the app's features exist (end of development) and **before** the three
listing/media skills — the name and the detected feature list it settles are their
inputs. Don't author the name fresh inside those skills — take it from the README
this skill maintains.

## The naming surfaces (what gets set, and who applies it)

| Surface | What it is | Where it lives | Applied by |
|--------|-----------|----------------|-----------|
| **On-device display name** | the name under the icon, in the window title / menu bar / About box | Xcode build settings (`PRODUCT_NAME`, `INFOPLIST_KEY_CFBundleDisplayName` / `CFBundleName`) or a hand-maintained Info.plist; per-locale via `InfoPlist.strings` | **this skill** → see [references/build-settings.md](references/build-settings.md) |
| **App Store name** | the title on the listing (≤30 chars), search-indexed | `fastlane/metadata/<locale>/name.txt` | `app-store-metadata` (files) — decided here |
| **Subtitle** | the one-liner under the name (≤30 chars), search-indexed | `fastlane/metadata/<locale>/subtitle.txt` | `app-store-metadata` (files) — decided here |
| **Source of truth** | the chosen names + ranked feature list, with rationale | the project `README.md` | **this skill** → see [references/readme-source-of-truth.md](references/readme-source-of-truth.md) |

The display name and the App Store name **do not have to match** — and renaming
the *display* is far less disruptive than renaming the Xcode target or the
bundle id (which you almost never want to touch). See the reference for the
"rename the display only vs. rename the target" decision.

## Workflow

### 1. Scan — detect the app's features and read the current names
Before proposing anything, learn what the app actually does, **build its feature
list**, and find what it's called today:
- **Detect the features from the finished code** — walk the menus/commands,
  settings/preferences, the feature-bearing views and models, and entitlements;
  each surfaced capability is a feature. Reuse the app's own wording (menu titles,
  button labels) rather than inventing. This detected list is what you'll rank and
  write into the README, so be thorough — it's the app's feature inventory.
- **Detect monetization** — check StoreKit products / a `.storekit` config and any
  `Pro`/`Premium` gating in the code. If there's a paid tier, capture the product
  id and what it unlocks; it becomes the `Pro` line in the identity block.
- Read any existing README and marketing copy for the app's real job, its hero
  feature, and its honest differentiators.
- Run `scripts/read_app_identity.sh [PROJECT_DIR]` to print the **current**
  on-device name, bundle id, target name, Info.plist / localized display names,
  and the README identity block. This is read-only and gives you the
  "current → proposed" baseline so a rename is a deliberate diff, not a guess.

### 2. Propose — ASO-aware candidates, with reasons
Offer a small set of candidates (typically 3–5) for the **app name**, and for
the **App Store name + subtitle** (these are usually richer than the on-device
name — e.g. display `Storeframe`, App Store `Storeframe: Localized Shots`,
subtitle `App Store screenshot maker`). For each, say *why* — what it conveys,
who it's for.

Run them past ASO before presenting: brief, plural/duplicate waste, the 30-char
limits on name and subtitle, and whether the high-value search terms live in the
name vs. the subtitle. **Draw on the `aso-keywords` skill for this** — it owns
the keyword strategy and the search-indexed-fields rules; don't reinvent that
analysis here, lift it. If `aso-keywords` isn't available, do a light local
pass (length, redundancy, the obvious search terms) and say so.

### 3. Discuss — the developer decides, not you
**Never pick the name unilaterally.** Naming is a product and brand decision the
developer owns; your job is to give them good options and sharpen their
thinking, then let them choose. Ask the questions that actually change the
answer:
- Who is the audience, and what's the one thing they should grasp from the name?
- Is there an existing brand / wordmark / domain to stay consistent with?
- Trademark or App Store name-collision concerns? (Flag the risk; you can't
  clear a trademark — say so.)
- Should the App Store name carry a keyword tail (`Name: keyword phrase`) or stay
  clean? Should the display name match the App Store name or be shorter?

Iterate on candidates with them until they pick. If they're undecided, narrow —
don't decide for them.

### 4. Apply — the on-device display name
Once the developer has chosen the **display name**, set it in the Xcode project
following [references/build-settings.md](references/build-settings.md): prefer
`PRODUCT_NAME` / `INFOPLIST_KEY_CFBundleDisplayName` over renaming the target or
bundle id, apply it to every relevant target (app + extensions/widgets/watch
app), add per-locale `InfoPlist.strings` only if the name should differ by
language, then verify the built `.app` shows the new name. Confirm before
editing the project file.

### 5. Record — write the source-of-truth README
This is the README finalization step — do it when the app is feature-complete so
the detected feature list matches the shipped software. Write into the project
`README.md` per [references/readme-source-of-truth.md](references/readme-source-of-truth.md):

1. The **identity block** — exactly these fields, in this order (the `Pro` line
   only when the app has a paid/Pro IAP tier; drop it for a fully-free app):

   ```markdown
   - **App name:** <on-device display name>
   - **App Store name:** <listing title, ≤30 chars>
   - **Subtitle:** <one-liner, ≤30 chars>
   - **Platform:** <e.g. macOS 14.6+>
   - **Bundle id:** `<com.acme.app>`
   - **Built with:** <stack, one line>
   - **Pro:** <one-time / subscription> (`<product id>`) — <what it unlocks>
   ```

2. The **detected, ranked feature list** (hero first; each feature one honest
   line, in the app's own wording).

This is the artifact the downstream skills read. Keep it truthful — it becomes
listing copy, so no invented claims. If a README already exists, update the
identity block in place and reconcile the feature list rather than clobbering the
developer's prose.

### 6. Hand off — point the listing/media skills at the README
The name + subtitle + features are now settled and recorded. Downstream:
- `aso-keywords` → optimize the chosen name/subtitle and fill the keyword field.
- `app-store-metadata` → write `name.txt` / `subtitle.txt` / `description.txt`
  from the README, validate limits, `deliver`.
- `appstore-media` → lift the ranked feature list as the screen story / captions.

Tell the user that's the next step; don't re-author the name in those skills.

## The core principle
You **propose and apply**; the developer **decides**. A name nobody chose on
purpose is worse than no rename at all — so the value here is the conversation
and the written-down rationale, not a clever auto-generated string. Scan, offer
real options with ASO and audience reasoning, and let the human land it.

## Boundaries
- You can't clear a trademark or guarantee an App Store name is free — surface
  the risk and tell the developer to verify in App Store Connect / a trademark
  search before committing.
- Renaming the Xcode **target**, **scheme**, or **bundle id** is invasive and
  rarely necessary just to change what users see — default to changing the
  display name only, and only touch the target/bundle id if the developer
  explicitly wants it (see the reference for the cost).
- Editing the project file is a code change — confirm before applying, and have
  the developer do a clean build to confirm the new name resolves.

## Reference files
- [references/build-settings.md](references/build-settings.md) — exactly where
  the on-device name lives and how to change it safely (build settings vs.
  Info.plist vs. target rename; per-target; per-locale; verification).
- [references/readme-source-of-truth.md](references/readme-source-of-truth.md) —
  the README structure this skill owns (identity block + ranked feature list)
  and how each downstream skill consumes it.

## Related skills
- `aso-keywords` — owns keyword strategy + the 100-char field; **this skill draws
  on it** when vetting name/subtitle candidates, then records the result.
- `app-store-metadata` — owns the fastlane metadata files; reads the chosen
  name/subtitle/description from the README this skill maintains.
- `appstore-media` — lifts the ranked feature list from the README as its screen
  story / captions.
- `ship-apple-app` — verifies (late) that the on-device name and the listing
  name/subtitle are present and consistent; this skill produces them (early).
- In the BD TECH studio flow, `app-profile` plays this source-of-truth role via
  `<slug>/profile.md`; standalone, the project README is the equivalent and this
  skill owns it.
