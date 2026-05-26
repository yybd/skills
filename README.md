# Skills

A repository of Skills for Claude and other language models. Each Skill is a self-contained package (a `.skill` file or a directory with a `SKILL.md`) that gives the model instructions, scripts, and reference files for handling a specific task.

The repo is organized by domain or platform (e.g. `apple/`, `web/`), and every Skill includes a `description` that helps the model recognize when it's relevant.

## Skills

### apple

- **[apple-app-store-screenshots](apple/apple-app-store-screenshots.skill)** — Converts any image into a screenshot that complies with Apple App Store Connect specifications (iPhone, iPad, Mac, Apple TV, Apple Watch, Apple Vision Pro). Produces a PNG at the exact pixel dimensions Apple requires, in RGB without an alpha channel, and handles aspect-ratio mismatches by asking the user how to fit the content (white/black/colored padding, blurred background, stretch, or crop) instead of silently distorting the image. Useful for App Store submissions, TestFlight uploads, or fixing screenshots that Apple rejected.

---

## Customer Project Structure

For a specific customer project, use this layout:

    ~/projects/clients/acme-electric/
    ├── CLAUDE.md      ← orchestrator
    ├── DESIGN.md      ← Acme brand design specification
    ├── PRODUCT.md     ← audience, voice, anti-references
    └── src/

General rule:

- Skills that are always useful across projects = `personal`
- Customer-specific instructions = `CLAUDE.md` in the project directory
- Design and brand specifications = `DESIGN.md` / `PRODUCT.md` in the project directory

## Role of Each Skill in the Flow

This prevents overlap by defining when each skill is active:

| Step | Active Skill | Responsibility |
|---|---|---|
| 1. Brand understanding | `landing-page-builder` | Reads the category and loads `references/categories/X.md` |
| 2. Aesthetic direction | `frontend-design` | Enforces tone, unique fonts, and unexpected layouts |
| 3. Page structure | `landing-page-builder` | Sets hero patterns, trust signals, and CTA hierarchy for the category |
| 4. Implementation | (Claude itself) | Writes the code |
| 5. Review | `web-design-guidelines` | Checks accessibility, performance, and 100+ UX rules |
| 6. Fixes | `frontend-design` | Corrects anti-patterns |

As more Skills are added, they will appear here under the appropriate domain.
