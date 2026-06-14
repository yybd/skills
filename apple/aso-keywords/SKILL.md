---
name: aso-keywords
description: >-
  App Store Optimization (ASO) for discoverability — research and optimize the
  search-indexed fields of an App Store listing: the app name, subtitle, and the
  100-character keywords field, per locale. Use this whenever the user wants to
  improve their app's search ranking / discoverability, choose or refine
  keywords, audit the keywords field, decide what to put in the name vs subtitle
  vs keywords, or expand to more locales for more keyword coverage. It audits the
  existing fields for ASO mistakes and suggests improvements. It optimizes the
  CONTENT for ranking; the app-store-metadata skill owns the files and validates
  limits.
---

# ASO Keywords & Discoverability

Most App Store traffic is search. The App Store indexes three fields together —
**app name**, **subtitle**, and the **100-character keywords field** — and ranks
on them. This skill helps the user use those fields well: no waste, no
redundancy, the right terms, multiplied across locales.

It's the strategy/optimization layer; `app-store-metadata` owns the actual files
and validates Apple's character limits. This skill reads those fields, audits
them for ASO, and proposes better content; metadata applies the changes.

> **In the BD TECH studio flow**, the name and subtitle come from the app's
> profile (`~/Developer/app-hub/<slug>/profile.md`) via `store-metadata-writer`,
> and the keyword *intent* is the app's own vocabulary already in the profile —
> lift and optimize from there rather than inventing a separate brand voice. This
> skill owns the **keyword strategy and the 100-char field**; `app-store-metadata`
> owns the files. Standalone (no profile), gather terms with the user as below.

## What this can and can't do
- ✅ **On-page ASO hygiene & structure** (fully here): field length usage,
  wasted characters, redundancy across name/subtitle/keywords, duplicate/plural
  waste, per-locale coverage, and concrete keyword suggestions from the app's
  purpose.
- ❌ **Search volume / difficulty / competitor rankings**: that needs paid data
  (AppTweak, Sensor Tower, etc.) — out of scope. Say so honestly; don't invent
  volume numbers. You can use web search for autocomplete-style ideas, but treat
  them as hypotheses.

## Workflow

### 1. Audit the current fields
```bash
python3 ~/.claude/skills/aso-keywords/scripts/analyze_keywords.py <project-root>
```
Per app + locale it reports name/subtitle/keywords length usage and flags the
classic mistakes: **words repeated** across name/subtitle/keywords (redundant —
they're indexed together, so repeating wastes space), **spaces after commas**
(wasted chars), **duplicate/again-pluralized** terms, an **under-used** or
**over-limit** keyword field, and an **empty** keyword field.

### 2. Understand the app and its users
Good keywords come from how users would search for *this* app, not generic terms.
Ask (or infer): what the app does, the category, the words a non-technical user
would type, and any strong differentiators. *(In the studio flow these are
already in the profile — lift them instead of asking cold.)* Avoid the app's brand name in
keywords (it already ranks for that) and avoid competitor trademarks (rejection
risk).

### 3. Optimize, following the rules in the guide
Apply [references/aso-guide.md](references/aso-guide.md):
- Put the **strongest term** in the name/subtitle (highest weight).
- Fill the keywords field with **distinct** terms (no repeats of name/subtitle),
  comma-separated, **no spaces**, singular OR plural (not both — the store
  matches stems), no plurals/duplicates, fit 100 chars.
- **Localize per store** — each locale is a fresh set of indexed terms; even
  "English (UK)" vs "English (US)" gives you a second keyword field.

### 4. Propose changes; let metadata apply them
Draft improved name/subtitle/keywords per locale and show the user. Once
approved, hand the actual file edits + limit-validation to the
`app-store-metadata` skill (it owns `keywords.txt` etc.). Keyword/marketing
wording is the user's call — present options, don't unilaterally rewrite their
brand voice.

## Reference files
- [references/aso-guide.md](references/aso-guide.md) — how App Store search
  indexing works, the rules for name/subtitle/keywords, localization strategy,
  and common mistakes.
- [scripts/analyze_keywords.py](scripts/analyze_keywords.py) — per-locale ASO
  hygiene audit of the indexed fields.
