# CLAUDE.md — Web Project Orchestrator

This file is the **orchestrator** for building this website. It defines the workflow, the intake you must run before building, and which skill handles which job. Brand/visual decisions live in `DESIGN.md`; audience/voice decisions live in `PRODUCT.md`. Read all three before building anything.

> Reusable template: this file is intended to be copied into each new web project. The "This Project" block below is the only part that changes per project. Everything else is general method.

---

## This Project

- **Name:** halacha-mishorsha
- **Type:** _TODO (set during intake)_
- **Stack:** _TODO (decided per intake — see Project Intake)_
- **Languages:** Hebrew (default), _add others as needed_
- **Direction:** RTL-first
- **Brand spec:** see `DESIGN.md`
- **Audience & voice:** see `PRODUCT.md`

---

## Baseline standards (apply to every project)

1. **i18n is on by default.** Wire multi-language support from the first commit using the right library for the stack. No hardcoded UI strings. See `.claude/skills/page-builder/references/i18n-rtl.md`.
2. **RTL is first-class.** Author with CSS logical properties; layouts mirror cleanly. Hebrew typography uses a real Hebrew font with proper line-height (and nikud support where content needs it).
3. **Mobile-first & responsive by default.** Build the phone layout first, then enhance upward. Verify on real iPhone and Android viewports (safe areas, `svh/dvh`, 44/48px tap targets, 16px inputs). See `.claude/skills/page-builder/references/responsive-mobile.md`.
4. **Content lives outside the markup.** Content prose goes in `text/<lang>/*.md` (one folder per language) rendered by a static engine; UI/button/nav strings stay in i18n catalogs; images/video go in `media/` (AVIF/WebP first); structured records go in an optional `data/` folder (only if the site uses data). See `.claude/skills/page-builder/references/content-architecture.md`.
5. **Structure before aesthetics before audit.** Follow the workflow phases below in order.
6. **Accessibility and performance are requirements, not extras.** The `web-design-guidelines` audit must pass before delivery.
7. **Never fabricate content.** Real testimonials, real numbers, real sources. Flag missing content as a TODO instead of inventing it.

---

## Project Intake — run this BEFORE building

When the user asks to build a page or site (or starts a new one), **always confirm these decisions first** using `AskUserQuestion`. Do not assume — the stack especially is decided fresh each time.

Ask:

1. **What are we building?** Landing page · homepage · product/marketing page · content/article site · docs · contact/lead · other.
2. **Stack** — recommend based on the answer to (1), but always ask:
   - Landing page / simple marketing → **HTML + CSS + JS** (no build step).
   - Dynamic app, user accounts, DB-backed or many pages → **Next.js + React**.
   - Content/SSG-friendly with growing page count → consider **Astro**.
   - Confirm the choice with the user every time.
3. **Languages & default** — which languages ship, and which is the default/fallback. (Default assumption: Hebrew-first, RTL.)
4. **Brand/design source** — is there a `DESIGN.md` to follow, an existing brand, or should we define a direction now?

Record the answers into the "This Project" block above and into `DESIGN.md` / `PRODUCT.md` as appropriate, then proceed.

---

## Workflow phases

Run in order. Use the skill named at each phase.

### 1. Structure — `page-builder`
Decide the page archetype, section order, hero pattern, trust-signal placement, and CTA hierarchy. Produce a section-by-section blueprint and confirm it (or proceed if told to just build). i18n/RTL structure is decided here, not later.

### 2. Aesthetics — `frontend-design`
Commit to a bold, cohesive visual direction per `DESIGN.md` (or define one if none exists). Typography, color, motion, spatial composition. Implement production-grade markup for the chosen stack.

### 3. Build
Implement the blueprint in the chosen stack with i18n + RTL wired in (logical CSS, translation catalogs, correct `lang`/`dir`) and mobile-first responsive layout (viewport meta with `viewport-fit=cover`, safe-area insets, `svh/dvh`, fluid type, `srcset`). Author content into `text/<lang>/*.md` (rendered by the static engine), UI strings into catalogs, and structured records into `data/` only if needed — see `.claude/skills/page-builder/references/content-architecture.md` and `responsive-mobile.md`. Wire in SEO/share metadata (`seo-metadata.md`), any form's submission/validation/privacy (`forms-conversion.md`), and the performance/font-loading budget (`performance.md`) as part of the build, not after. For UI work, run the app and check it in a browser — golden path plus RTL, an iPhone viewport, and an Android viewport at 320–360px.

### 4. Audit — `web-design-guidelines`
Run the accessibility / performance / UX guideline review against the built files. Fix findings.

### 5. Pre-delivery
Run `.claude/skills/page-builder/references/checklists/pre-delivery.md`. List any remaining content TODOs and known limitations for the user.

---

## Skill routing — quick reference

| Need | Skill |
|------|-------|
| "What sections, in what order?" / page skeleton | `page-builder` |
| "Make it look striking" / typography, color, motion | `frontend-design` |
| "Review my UI / check accessibility / audit UX" | `web-design-guidelines` |
| Multi-language + RTL architecture details | `page-builder/references/i18n-rtl.md` |
| SEO, share cards (WhatsApp/OG), structured data, sitemap, favicons | `page-builder/references/seo-metadata.md` |
| Sign-up / lead / contact form mechanics + privacy/PII | `page-builder/references/forms-conversion.md` |
| Performance budget + Hebrew font-loading strategy | `page-builder/references/performance.md` |

The skills are in `.claude/skills/`. They are reusable across projects and intended to be packaged as a plugin later — keep them project-agnostic. Anything specific to *this* customer belongs in `CLAUDE.md` / `DESIGN.md` / `PRODUCT.md`, not in a skill.

---

## Project file map

```
halacha-mishorsha/
├── CLAUDE.md            ← this orchestrator
├── DESIGN.md            ← brand & visual spec
├── PRODUCT.md           ← audience, voice, anti-references
├── docs/web/customer-project-workflow.md
├── .claude/skills/
│   ├── page-builder/
│   ├── frontend-design/
│   └── web-design-guidelines/
└── src/                 ← the site (created during build)
    ├── text/<lang>/*.md ← content prose, one folder per language
    ├── media/           ← images / video (AVIF/WebP first, SVG icons)
    └── data/            ← optional: structured records (products, etc.)
```

See `docs/web/customer-project-workflow.md` for the full method and how these pieces fit together.
