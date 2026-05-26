# Customer Project Workflow

This document describes how to structure and operate client-specific projects in the Skills workspace.

## Purpose

Use this workflow for customer projects that include general brand guidance, product context, and a project-specific orchestrator.

## Project structure

For a single customer project, use this layout:

    ~/projects/clients/acme-electric/
    ├── CLAUDE.md      ← project orchestrator and customer-specific instructions
    ├── DESIGN.md      ← brand and design specification for Acme
    ├── PRODUCT.md     ← audience, voice, anti-references, and product guidance
    └── src/           ← implementation code or generated assets

## What belongs where

- `personal` skills: reusable capabilities that apply across all projects and clients.
- `CLAUDE.md`: customer-specific orchestration, unique instructions, rules and priorities for the current client.
- `DESIGN.md`: brand identity, visual system, color, typography, tone, and style preferences.
- `PRODUCT.md`: target audience, voice, product positioning, customer language, anti-references, and product-level constraints.

## Skill roles in the flow

This workflow prevents collisions by assigning each skill a distinct role and activation point.

| Step | Active Skill | What it does |
|---|---|---|
| 1. Brand understanding | `landing-page-builder` | Reads the category and loads category reference files (`references/categories/X.md`).
| 2. Aesthetic direction | `frontend-design` | Chooses tone, fonts, layouts, and visual direction.
| 3. Page structure | `landing-page-builder` | Defines hero patterns, trust signals, CTA hierarchy, and content structure.
| 4. Implementation | (Claude itself) | Generates the actual code or page artifacts.
| 5. Review | `web-design-guidelines` | Checks accessibility, performance, UX, and design rules.
| 6. Fixes | `frontend-design` | Cleans up anti-patterns and strengthens the final visual result.

## Coordination rules

- Always prefer `personal` skills for reusable logic, design patterns, or shared capabilities.
- Keep customer-specific directives inside `CLAUDE.md` so the orchestrator is the source of truth for the project.
- Place brand and product-level direction in `DESIGN.md` and `PRODUCT.md`, not directly in shared skills.
- Use the skill flow to make the problem deterministic and avoid multiple skills changing the same artifact at once.

## Why this matters

This structure keeps client projects organized and readable, and it makes the overall AI workflow predictable:

- `CLAUDE.md` is the project-specific brain.
- `DESIGN.md` and `PRODUCT.md` are the brand and product references.
- Skills like `landing-page-builder`, `frontend-design`, and `web-design-guidelines` each act at a defined phase.

## Example

For `acme-electric`:

- `CLAUDE.md` can instruct how to interpret the brand, which sections to prioritize, and what output format is required.
- `DESIGN.md` describes the Acme look and feel: colors, imagery style, typography, and visual tone.
- `PRODUCT.md` describes Acme's audience, tone of voice, competitor anti-patterns, and buyer motivations.

When the workflow runs, the project harnesses reusable skills while still honoring the client’s unique identity.
