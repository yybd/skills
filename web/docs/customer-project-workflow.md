# Customer Project Workflow

How the web skills, the orchestrator, and the per-project spec files fit together to build a site. Read this once to understand the method; the day-to-day rules live in `CLAUDE.md`.

## Why this system (vs. a one-line prompt)

A fair question: if you just say *"let's build a sign-up page for a daily-halacha WhatsApp"*, won't Claude Code do most of this on its own? Mostly yes — about 70–80% of it. So why the system?

**The real comparison isn't "system vs. short prompt." It's "system vs. the long, perfect prompt you'd have to rewrite — flawlessly — for every single site."** This system *is* that prompt, written once and made to never forget a detail.

What you gain over a bare prompt:

| Without the system | With the system |
|--------------------|-----------------|
| Claude guesses a stack | Intake **asks** every time (landing→HTML, dynamic→Next, content→Astro) |
| Builds straight through | **Stops for your approval** at intake, blueprint, and design direction |
| i18n/RTL often bolted on later | i18n + RTL wired from commit one — **never forgotten** |
| Desktop-first, mobile patched | iPhone/Android safe-areas, `svh/dvh`, tap targets **by default** |
| Strings hardcoded in markup | Content in `text/<lang>/`, UI in catalogs — **separated by default** |
| May invent testimonials/numbers | **No fabricated content** — gaps flagged as TODO |
| Different look & rigor each time | A **consistent baseline** across every site you build |

Three things it buys you specifically:
- **Control** — three explicit checkpoints (intake, blueprint, design) instead of one big unreviewed generation.
- **Consistency** — every site you ship clears the same baseline, so quality doesn't depend on what you remembered to type that day.
- **Your standards, encoded** — your specific opinions (Hebrew-first RTL, mobile-first, no fabricated proof, content out of markup) are baked in, not re-argued each time.

**When it's *not* worth it:** a one-off throwaway, a quick prototype, or a single static page you'll never revisit. For those, a short prompt is genuinely fine. The system pays off when you're building *many* sites and want each to start from the same high floor.

## The mental model

Three reusable **skills** define *method* (project-agnostic). Three per-project **files** define *this customer* (specific). The orchestrator ties them together.

```
Reusable (copy to every project, later a plugin)      Per-project (one per customer)
─────────────────────────────────────────────        ──────────────────────────────
.claude/skills/page-builder/        ← structure       CLAUDE.md   ← orchestrator + intake
.claude/skills/frontend-design/     ← aesthetics       DESIGN.md   ← brand & visual spec
.claude/skills/web-design-guidelines/ ← audit          PRODUCT.md  ← audience, voice, anti-refs
```

**Rule of thumb:**
- Always-useful method → a **skill** (project-agnostic, no customer details).
- Customer-specific instructions → **CLAUDE.md** in the project.
- Brand/visual decisions → **DESIGN.md**.
- Audience/voice/messaging → **PRODUCT.md**.

If you ever find customer specifics leaking into a skill, move them out — skills must stay portable so they can be copied across projects and eventually packaged as a Claude Code plugin.

## Folder structure for a customer project

```
~/Developer/web/<customer>/
├── CLAUDE.md            ← orchestrator (intake + workflow + routing)
├── DESIGN.md            ← brand & visual specification
├── PRODUCT.md           ← audience, voice, anti-references
├── docs/web/
│   ├── customer-project-workflow.md      ← this file (English)
│   └── customer-project-workflow.he.md   ← Hebrew version
├── .claude/skills/
│   ├── page-builder/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── page-archetypes.md
│   │       ├── i18n-rtl.md
│   │       ├── responsive-mobile.md
│   │       ├── content-architecture.md
│   │       ├── seo-metadata.md
│   │       ├── forms-conversion.md
│   │       ├── performance.md
│   │       ├── sections/{hero-patterns, trust-signals, cta-hierarchy}.md
│   │       └── checklists/pre-delivery.md
│   ├── frontend-design/
│   │   ├── SKILL.md
│   │   └── references/techniques.md
│   └── web-design-guidelines/SKILL.md
└── src/                 ← the actual site
    ├── text/<lang>/*.md ← content prose, one folder per language
    ├── media/           ← images / video (AVIF/WebP first, SVG icons)
    └── data/            ← optional: structured records
```

> Skill location matters: Claude Code only discovers skills under `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (personal). A skill placed directly in `.claude/<name>/` is **not** discovered.

## Skills in detail

### `page-builder` — structure (what goes on the page, in what order)
Runs first. Decides the page skeleton before any visual design. Its `SKILL.md` drives the process and pulls in references as needed:

- **`references/page-archetypes.md`** — proven section orders per page type (landing, homepage, product, content/article, docs, contact, pricing), **plus system & state pages (404, error, empty, loading)** + how to choose between them.
- **`references/sections/hero-patterns.md`** — hero variants (centered, split, inline-form, background-media, editorial, interactive) and selection guide.
- **`references/sections/trust-signals.md`** — doubt→proof mapping, proof types ranked, and placement rules.
- **`references/sections/cta-hierarchy.md`** — the "rule of one" primary CTA, copy, and where to repeat it.
- **`references/i18n-rtl.md`** — multi-language architecture + RTL-first rules, with stack-specific libraries and Hebrew typography guidance.
- **`references/responsive-mobile.md`** — mobile-first method, breakpoints, touch ergonomics, safe areas, and iPhone/Android Safari/Chrome gotchas.
- **`references/content-architecture.md`** — content/UI text split, `text/<lang>/*.md` layout, the static rendering engine per stack, the `media/` assets folder (AVIF/WebP), and the optional `data/` directory.
- **`references/seo-metadata.md`** — per-page title/meta, canonical, `hreflang`, Open Graph/Twitter share cards (the WhatsApp/Facebook preview), JSON-LD/Schema.org, sitemap/robots, and the favicon/manifest/site-chrome set.
- **`references/forms-conversion.md`** — when the goal is a submission: the submission path, accessible/RTL form markup, validation, spam defense, the four states, and the privacy/PII obligations (consent, privacy policy, minimization).
- **`references/performance.md`** — concrete Core Web Vitals budgets and the Hebrew-first font-loading strategy (self-host, subset incl. nikud, `font-display`, preload), plus image/CSS/JS delivery.
- **`references/checklists/pre-delivery.md`** — final structural QA gate (goal, hero, trust, CTAs, content, content-architecture, i18n/RTL, responsive, SEO, forms, performance, basics).

### `frontend-design` — aesthetics (how it looks)
Runs second. Commits to a bold, cohesive visual direction (typography, color, motion, composition) per `DESIGN.md`, and implements production-grade markup. Project-agnostic; brand decisions come from `DESIGN.md`. Its `references/techniques.md` holds concrete four-vector patterns (font pairings incl. Hebrew faces, themes, staggered-load motion, layered backgrounds, an AI-slop checklist, and a baseline-compliant quick-start template) — treated as starting points to vary, never defaults.

### `web-design-guidelines` — audit (is it correct)
Runs last. Fetches the current Web Interface Guidelines and reviews the built files for accessibility, performance, and UX compliance, reporting findings in `file:line` format.

## How the spec files are loaded

- **`CLAUDE.md` is loaded automatically** by Claude Code (it is the project memory at the repo root) — it is always in context.
- **`DESIGN.md` and `PRODUCT.md` are NOT auto-loaded.** They are plain files, read only when the workflow calls for it. The trigger is the instruction inside `CLAUDE.md` ("Read all three before building anything"), which is honored at intake and at the relevant phase: `page-builder` consults `PRODUCT.md` (audience, voice, which proof is needed); `frontend-design` consults `DESIGN.md` (brand, color, type, motion).
- Practical implication: keep the reading discipline — at the start of any build, read `DESIGN.md` and `PRODUCT.md` before producing structure or visuals. (No hook is configured; loading is guided by `CLAUDE.md`.)

## The skill flow (per page or site)

1. **Intake (CLAUDE.md).** Before building, confirm: what we're building, the stack (asked every time — landing page → HTML/CSS/JS, dynamic → Next.js+React, content-heavy → Astro), languages + default, and brand source. Record answers into the "This Project" block and the spec files.
2. **Structure (`page-builder`).** Pick the archetype, section order, hero pattern, trust placement, CTA hierarchy. i18n/RTL structure is decided here. Output a blueprint and confirm it.
3. **Aesthetics (`frontend-design`).** Commit to a bold direction per `DESIGN.md`; implement production-grade UI in the chosen stack.
4. **Build.** Implement with i18n + RTL wired in from the start (translation catalogs, logical CSS, correct `lang`/`dir`). Verify in a browser including an RTL and small-screen pass.
5. **Audit (`web-design-guidelines`).** Run the accessibility/performance/UX review; fix findings.
6. **Pre-delivery.** Run `page-builder/references/checklists/pre-delivery.md`; report remaining content TODOs.

## The flow at a glance (and when each spec file is written)

```
You: "let's build X"
   ↓
Intake (4 questions)  → 📝 CLAUDE.md updated + decide the brand source   ← the DESIGN.md decision happens here
   ↓
page-builder          → blueprint; you approve it                        → 📝 PRODUCT.md (when audience/voice surfaces)
   ↓
frontend-design       → design dialogue; you approve a direction         → 📝 DESIGN.md filled in for real   ← the DESIGN.md fill happens here
   ↓
build                 → reads DESIGN.md + PRODUCT.md, authors content into text/<lang>/
   ↓
audit (web-design-guidelines) + pre-delivery
```

Two key points:
- **`DESIGN.md` is filled through dialogue, not up front** — the template ships with `TODO`s; it gets *populated* during the `frontend-design` phase when you approve a visual direction. (If you already have a brand, it's filled during intake instead.)
- **You approve before each phase continues** — intake, blueprint, and design direction are three checkpoints.

## Baseline standards (every project)

- **i18n on by default** — multi-language support wired from commit one, no hardcoded strings, right library per stack.
- **RTL first-class** — logical CSS properties, clean mirroring, real Hebrew typography (nikud where needed).
- **Mobile-first & responsive** — phone layout first, verified on real iPhone + Android viewports (safe areas, `svh/dvh`, 44/48px tap targets, 16px inputs). See `page-builder/references/responsive-mobile.md`.
- **Content outside the markup** — content prose in `text/<lang>/*.md` (static engine renders it), UI strings in catalogs, structured records in optional `data/`. See `page-builder/references/content-architecture.md`.
- **No fabricated content** — real proof and sources only; flag gaps as TODOs.
- **Accessibility & performance are requirements**, gated by the `web-design-guidelines` audit.

## Starting a new customer project

1. Create the folder and copy `CLAUDE.md`, `DESIGN.md`, `PRODUCT.md`, and `.claude/skills/` from an existing project (or, once packaged, install the plugin).
2. Update the "This Project" block in `CLAUDE.md`.
3. Fill `DESIGN.md` and `PRODUCT.md` (or leave TODOs and resolve them during intake).
4. Run the intake and proceed through the workflow phases.

## Toward a plugin

The three skills plus this doc are designed to be packaged as a Claude Code plugin so new projects get them without copying files. Keep skills free of customer specifics so the eventual extraction is clean: only `CLAUDE.md` / `DESIGN.md` / `PRODUCT.md` should differ between customers.
