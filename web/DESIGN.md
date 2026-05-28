# DESIGN.md — Brand & Visual Specification

The single source of truth for *how this site looks and feels*. The `frontend-design` skill reads this to stay on-brand instead of inventing a new aesthetic each time. Fill every `TODO`; delete guidance notes once decided.

> Template note: this file is reusable. Replace the placeholders with real decisions for **halacha-mishorsha**.

---

## 1. Brand essence

- **Project:** halacha-mishorsha
- **One-line essence:** _TODO — what feeling should a visitor walk away with? (e.g., "clear, trustworthy, rooted halachic guidance")_
- **Personality (3–5 adjectives):** _TODO — e.g., scholarly, warm, precise, accessible_
- **Aesthetic direction:** _TODO — pick a clear lane (editorial / refined-minimal / classic-traditional / modern-serif …). Avoid generic AI defaults._
- **Inspiration / references:** _TODO — links or names of sites whose feel you admire_

## 2. Color

Define as CSS variables; commit to a dominant color + sharp accent, not a timid even palette.

- **Background:** _TODO_
- **Surface / cards:** _TODO_
- **Text (primary / muted):** _TODO_
- **Brand / primary accent:** _TODO_
- **Secondary accent:** _TODO_
- **Semantic:** success / warning / error _TODO_
- **Theme:** light / dark / both — _TODO_
- Contrast: all text/background pairs must meet WCAG AA (4.5:1 body, 3:1 large).

## 3. Typography

RTL/Hebrew-first — choose fonts with a real Hebrew cut (see `.claude/skills/page-builder/references/i18n-rtl.md`).

- **Display / headings (Hebrew):** _TODO — e.g., Frank Ruhl Libre, Heebo_
- **Body (Hebrew):** _TODO — e.g., Assistant, Noto Sans Hebrew_
- **Latin pairing (for en / mixed):** _TODO_
- **Scale:** _TODO — type scale + base size_
- **Line-height:** Hebrew needs more than latin — _TODO per script_
- **Nikud:** required? _TODO_ — if yes, verify the font renders it correctly.

## 4. Spacing & layout

- **Spacing scale:** _TODO (e.g., 4px base / 8-pt grid)_
- **Container max-width & gutters:** _TODO_
- **Grid:** _TODO_
- **Border radius / shape language:** _TODO_
- **Authoring rule:** use CSS logical properties only — layouts must mirror cleanly in RTL.

## 5. Components

Define the recurring building blocks so they stay consistent:

- **Buttons:** primary / secondary / tertiary — sizes, states, radius. _TODO_
- **Links:** style + focus-visible. _TODO_
- **Cards:** _TODO_
- **Forms / inputs:** _TODO (RTL-aware, `dir="auto"` on free text)_
- **Navigation / header / footer:** _TODO_

## 6. Motion

- **Personality:** _TODO — subtle/refined vs. expressive_
- **Signature moment:** _TODO — e.g., one staggered hero reveal on load_
- **Library:** CSS-first for static; Motion for React. _TODO_
- Respect `prefers-reduced-motion`.

## 7. Imagery & texture

- **Style:** photography / illustration / iconography / pattern. _TODO_
- **Texture & atmosphere:** _TODO — gradients, grain, geometry; avoid flat default-blue gradients_
- **Iconography set:** _TODO_

## 8. Do / Don't

- **Do:** _TODO_
- **Don't:** _TODO — explicit anti-patterns (e.g., no Inter/Roboto, no purple-on-white gradient, no carousel hero)_

---

When a decision isn't recorded here, the `frontend-design` skill should make a bold, context-appropriate choice — then add it back into this file so it becomes canonical.
