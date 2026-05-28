# Content Architecture (text/ + data/ + static engine)

**Baseline convention for every project unless the user opts out.** Keep the site's *content* out of the markup. Two kinds of text are handled differently:

| Kind | Examples | Where it lives |
|------|----------|----------------|
| **Content text** | article/section bodies, headings that are content, prose, FAQ answers, page copy | `text/<lang>/*.md` (Markdown) |
| **UI / chrome text** | button labels, nav items, form labels, validation/error messages, aria labels | i18n message catalogs (JSON), per `i18n-rtl.md` |

This split is deliberate: content is long-form, edited often, and authored in Markdown; UI strings are short, keyed, and belong in the translation catalog. Never hardcode either into the markup.

## Directory layout

```
src/
├── text/                      ← all CONTENT text, one folder per language
│   ├── he/
│   │   ├── home.md
│   │   ├── about.md
│   │   └── halacha/
│   │       └── shabbat.md      ← sub-paths allowed for nested content
│   └── en/
│       ├── home.md
│       └── about.md
├── data/                      ← OPTIONAL — structured data, only if the site needs it
│   ├── products.json
│   └── team.json
├── media/                     ← all images / video / downloadable assets
│   ├── hero.avif
│   ├── hero.webp
│   ├── logo.svg
│   └── he/                    ← per-locale subfolder ONLY for media with baked-in text
│       └── og.png
└── ... (markup, styles, engine)
```

- **One language folder per language**, mirroring the same file tree so a translator can see exactly what's missing.
- The **default/fallback language** (e.g. `he`) must be complete; the engine falls back to it when a file is missing in another language.
- File names are stable content IDs (`home`, `about`, `halacha/shabbat`) — they're referenced from the markup, so don't rename casually.

## Markdown content files

Each `.md` file may start with optional YAML front-matter for metadata, followed by the content body:

```markdown
---
title: ברוכים הבאים
description: עמוד הבית
order: 1
---

## כותרת תוכן

גוף הטקסט בעברית, **Markdown** מלא, רשימות, קישורים, ציטוטים.

> מקור: שולחן ערוך, אורח חיים …
```

- Front-matter holds content metadata (title, description, order, tags, source/מקורות) — handy for content pages and listing/sorting.
- The body is pure content. Do **not** put button labels or nav text here.
- For Torah/halacha content, use front-matter for source citations (מקורות) and a field distinguishing ruling vs. discussion (see `page-archetypes.md`).

## The static content engine

A small engine reads the right `text/<lang>/…` file, renders the Markdown, and injects it into designated slots. **Implementation depends on the stack** — pick the one that preserves SEO:

### Plain HTML/CSS/JS (runtime engine)
Mark slots in the markup, then load + render at runtime:

```html
<main>
  <section data-content="home/hero"></section>
  <section data-content="home/about"></section>
</main>
<script type="module" src="/js/content-engine.js"></script>
```

```js
// content-engine.js — minimal static content loader
import { marked } from "https://cdn.jsdelivr.net/npm/marked/lib/marked.esm.js";

const DEFAULT_LANG = "he";
const lang = document.documentElement.lang || DEFAULT_LANG;

async function fetchMarkdown(path, lng) {
  const res = await fetch(`/text/${lng}/${path}.md`);
  return res.ok ? res.text() : null;
}

function stripFrontMatter(md) {
  return md.replace(/^---\n[\s\S]*?\n---\n/, "");
}

async function loadContent() {
  const slots = document.querySelectorAll("[data-content]");
  await Promise.all([...slots].map(async (el) => {
    const path = el.dataset.content;                 // e.g. "home/hero"
    let md = await fetchMarkdown(path, lang);
    if (md == null && lang !== DEFAULT_LANG) {        // fallback to default lang
      md = await fetchMarkdown(path, DEFAULT_LANG);
    }
    if (md == null) return;                           // leave slot empty if truly missing
    el.innerHTML = marked.parse(stripFrontMatter(md));
  }));
}
loadContent();
```

> **SEO caveat:** a purely client-side fetch+inject means content is not in the initial HTML, which hurts indexing and first paint. For content/marketing sites that need SEO, **prefer build-time rendering** (below) or pre-render the pages. Runtime injection is fine for app-like or non-indexed UIs.

### Next.js / React (build-time, SEO-safe)
Read the Markdown at build/server time so content ships in the HTML:
- Import per-locale Markdown (e.g. with `gray-matter` for front-matter + `remark`/`MDX`, or a content layer).
- Resolve `text/<locale>/<slug>.md` from the route's locale; fall back to the default locale.
- Render server-side; pair with the `next-intl` catalog for UI strings (`i18n-rtl.md`).

### Astro (build-time, SEO-safe)
Use **content collections**: define a `text` collection, one entry per `<lang>/<slug>.md`, render at build. Astro's `astro:i18n` handles locale routing; UI strings still come from catalogs.

## The `data/` directory (optional)

Only add `data/` when the site has **structured, repeated records** — a product list, team/users, pricing tiers, a glossary. Skip it for purely editorial sites.

- **Format:** JSON or YAML for structured records; CSV is acceptable for flat tabular data. Pick one and be consistent.
- **Language strategy for data** (choose per project):
  - **Language-neutral + localized fields** (recommended for small sets): one file where each record carries localized fields, e.g.
    ```json
    { "id": "p1", "price": 49, "image": "/img/p1.webp",
      "name": { "he": "מוצר", "en": "Product" } }
    ```
  - **Per-language data files** (for large localized datasets): mirror the `text/` pattern — `data/he/products.json`, `data/en/products.json`.
  - Keep language-neutral facts (ids, prices, SKUs, image paths) in one place; never duplicate a price across languages.
- The engine loads `data/*` and renders it through templates, merging with `text/` copy where a record needs prose.
- **Never put secrets or real user PII in `data/`** if the site is static/public — `data/` ships to the client. Use it for public catalog-style data only.

## Media assets (`media/`)

All images, video, and downloadable files live in **`src/media/`** — not scattered next to markup, not in `text/` or `data/`. Keep the folder flat or grouped by section; use stable, descriptive file names (they're referenced from markup and content).

- **Formats — modern first:** ship **AVIF and/or WebP** as the primary format with a sensible fallback; never serve desktop-weight JPEG/PNG to phones. SVG for logos, icons, and line art. See `performance.md` for compression and `responsive-mobile.md` for `srcset`/`sizes`.
  ```html
  <picture>
    <source srcset="/media/hero.avif" type="image/avif">
    <source srcset="/media/hero.webp" type="image/webp">
    <img src="/media/hero.jpg" width="1200" height="630" alt="">
  </picture>
  ```
- **Provide multiple widths** for responsive `srcset` (e.g. `hero-640.webp`, `hero-1280.webp`) so phones don't download desktop images.
- **Always set `width`/`height` or `aspect-ratio`** to prevent layout shift (CLS).
- **Locale-neutral by default.** Put media in `media/` directly. Only create a per-locale subfolder (`media/he/`, `media/en/`) for assets with **baked-in text** — and prefer live text over baked-in (see `i18n-rtl.md`). OG share images with text are the common case (`seo-metadata.md`).
- **`alt` text is content** — it comes from the i18n catalog / content, not hardcoded; decorative images get `alt=""`.
- **Don't inline large media as base64** in markup/CSS — it defeats caching; reference files from `media/`.

## Why this split pays off

- Translators and content editors touch only `text/<lang>/` and `data/` — never the code.
- Adding a language = adding one folder under `text/` (and `data/<lang>/` if used).
- Markup stays clean: structure in HTML/components, content in Markdown, UI strings in catalogs.
- Missing translations degrade gracefully via default-language fallback.

## Acceptance check

- [ ] No content prose hardcoded in markup — it lives in `text/<lang>/*.md`.
- [ ] No UI/button/nav strings in `text/` — those are in the i18n catalog.
- [ ] Every language folder mirrors the default-language file tree; fallback works for missing files.
- [ ] Content loads correctly and sets `lang`/`dir` per language.
- [ ] SEO-critical pages render content at build time (not client-only) — or are pre-rendered.
- [ ] `data/` exists only if the site uses structured records; no secrets/PII in a static `data/`.
- [ ] All images/video live in `media/` (AVIF/WebP first, SVG for icons); sized to prevent CLS; `alt` from content.
- [ ] Markdown front-matter used for content metadata (title, order, sources/מקורות) where helpful.
