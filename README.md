# Skills

A repository of Skills for Claude and other language models. Each Skill is a self-contained package (a `.skill` file or a directory with a `SKILL.md`) that gives the model instructions, scripts, and reference files for handling a specific task.

The repo is organized by domain or platform (e.g. `apple/`, `web/`), and every Skill includes a `description` that helps the model recognize when it's relevant.

## Skills

### apple

- **[apple-app-store-screenshots](apple/apple-app-store-screenshots.skill)** — Converts any image into a screenshot that complies with Apple App Store Connect specifications (iPhone, iPad, Mac, Apple TV, Apple Watch, Apple Vision Pro). Produces a PNG at the exact pixel dimensions Apple requires, in RGB without an alpha channel, and handles aspect-ratio mismatches by asking the user how to fit the content (white/black/colored padding, blurred background, stretch, or crop) instead of silently distorting the image. Useful for App Store submissions, TestFlight uploads, or fixing screenshots that Apple rejected.

---

As more Skills are added, they will appear here under the appropriate domain.
