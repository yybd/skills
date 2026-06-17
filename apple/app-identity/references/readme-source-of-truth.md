# The project README as the source of truth

For a standalone Apple app, the repo's own `README.md` is the **single source of
truth** for the app's identity and story: the chosen names, the subtitle, and
the ranked feature list. Everything else — the App Store listing, the keyword
field, the screenshot captions — is *derived* from it. This skill owns it: it
writes it after the naming conversation, and keeps it the one place those facts
live.

This is the standalone analog of the studio's `<slug>/profile.md`. When a BD
TECH hub profile exists, that is the deeper source of truth — but the hub's
`app-profile` skill itself reads this README first (it runs *after* `app-identity`
and lifts the names + feature ranking from here before enriching with code +
market research). So writing the README well pays off in both flows.

## Structure this skill maintains

Keep the README readable for humans first — it's still a developer's README —
but make sure these two pieces are present and accurate, because they're what
gets lifted downstream.

### 1. Identity block (top of the file)

```markdown
# <On-device display name>

<One- or two-line factual description: core function + platform.>

- **App name:** <on-device display name — what users see under the icon / in the menu bar>
- **App Store name:** <listing title, ≤30 chars; may carry a keyword tail, e.g. "Storeframe: Localized Shots">
- **Subtitle:** <one-liner under the name, ≤30 chars>
- **Platform:** <e.g. macOS 14.6+ / iOS 17+>
- **Bundle id:** `<com.acme.app>`
- **Built with:** <stack, one line>
- **Pro:** <one-time / subscription> (`<product id>`) — <what it unlocks>   ← only if the app has a paid/Pro tier
```

The fields and their order are fixed; include `Pro` only when the scan found a
paid/premium IAP tier (StoreKit product / `.storekit` config), and drop it for a
fully-free app. The **App name** here must match what `read_app_identity.sh`
reports from the build settings — if they disagree, the README is wrong or the
rename is incomplete; reconcile them. The **App Store name** and **Subtitle** are
the decided values that `app-store-metadata` will write to `name.txt` /
`subtitle.txt`.

**Filled example** (this very project — note the `Pro` line, since it has a Pro IAP):

```markdown
# Storeframe

A native macOS app that turns a single raw screenshot into polished, localized,
App Store–ready marketing screenshots.

- **App name:** Storeframe
- **App Store name:** Storeframe: Localized Shots
- **Subtitle:** App Store screenshot maker
- **Platform:** macOS 14.6+ (some features require macOS 15+, see notes)
- **Bundle id:** `com.yybd.AppStoreAssetsGenerator`
- **Built with:** SwiftUI + AppKit, fully offline
- **Pro:** one-time non-consumable (`com.yybd.AppStoreAssetsGenerator.pro`) — multi-language export, on-device auto-translation, App Store Connect upload
```

### 2. Ranked feature list

A `## Features` section, hero feature first, each feature an honest one-line
claim (group into subsections if the app is large). This is the **screen story**
`appstore-media` lifts and the raw material for `app-store-metadata`'s
description. Rank by what a buyer cares about, not by code structure.

```markdown
## Features

### <Group>
- **<Feature>** — <what it does, concretely; the benefit, no hype>.
```

Truthfulness rule: this becomes listing copy. Every line must trace to something
the app actually does. No invented claims, no marketing inflation — if you can't
ground it, it's a question for the developer, not a guess.

## How downstream skills consume it

| Skill | Reads from the README | Produces |
|-------|----------------------|----------|
| `aso-keywords` | App name + Subtitle | optimized name/subtitle + the 100-char keyword field |
| `app-store-metadata` | App name → `name.txt`, Subtitle → `subtitle.txt`, features → `description.txt` | the fastlane metadata files (validated, `deliver`) |
| `appstore-media` | the ranked feature list | the screen story / screenshot captions |
| `app-profile` (BD TECH hub) | identity block + feature list, as an authored input | `<slug>/profile.md` (enriched with code scan + market research) |

## Maintenance rules
- **Don't clobber.** If a README already exists, update the identity block and
  reconcile the feature list; preserve the developer's existing prose, structure,
  and any sections (build instructions, project layout, license) that aren't
  identity/features.
- **Keep it in sync with the build settings.** Whenever the display name changes
  in Xcode, update the `App name` line here (and vice versa) — they are the same
  fact in two places and must not drift.
- **One source of truth.** Resist duplicating the names/subtitle into other docs;
  point them at the README instead.
