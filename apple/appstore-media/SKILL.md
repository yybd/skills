---
name: appstore-media
description: End-to-end pipeline for producing App Store-compliant screenshots and App Preview videos for iOS and macOS apps, driven by a scripted, repeatable XCUITest demo flow. Use this skill whenever the user wants App Store screenshots, an app preview video, a demo/marketing recording of their app, simulator capture, fastlane snapshot setup, marketing captions for screenshots, an iMovie editing plan, or asks to verify media against Apple's required formats — even if they only say "I need screenshots for my app", "תכין צילומי מסך", "סרטון לאפסטור", or similar. Also use when adding accessibility identifiers or a demo mode to an app specifically for capture purposes.
---

# App Store Media Pipeline (iOS + macOS)

Produce professional, App Store-compliant screenshots and App Preview videos from a **single scripted demo flow** per app. The flow is an XCUITest that drives the app like a user; running it produces screenshots in every locale and a raw video, which scripts then convert and verify against Apple's exact specifications. The user finishes the job in iMovie (video text overlays) and a screenshot-framing tool, guided by a marketing-copy plan this skill generates.

**Language**: The user is a Hebrew speaker. Write all conversation, summaries, explanations, and the marketing-copy deliverables in **Hebrew** (with English copy variants where the deliverable itself needs English). Write all code, scripts, and identifiers in English. Apps are typically localized to Hebrew (`he`) and English (`en-US`) — confirm which locales to produce.

## The five phases

Work through these in order. Each phase has a reference file — read it when you reach that phase, not before.

```
Phase 0  Discover        → interview + inspect the Xcode project
Phase 1  Prepare the app → demo mode, accessibility IDs, seeded data
Phase 2  Script the flow → XCUITest demo flow   (references/xcuitest-flow.md)
Phase 3  Capture         → scripts/capture_ios.sh / capture_mac.sh
Phase 4  Convert+verify  → scripts/convert_preview.sh, scripts/verify_assets.py
Phase 5  Copy + editing  → captions & iMovie plan (references/marketing-copy.md)
```

Apple's exact format requirements (resolutions, codecs, durations, content rules) live in `references/apple-specs.md`. Read it before Phase 3 and keep it in mind throughout — **capturing at the wrong size wastes an entire run**.

## Phase 0 — Discover

Before writing anything, build a picture of the app:

1. Inspect the project: find the `.xcodeproj`/`.xcworkspace`, list schemes (`xcodebuild -list`), determine platform(s) (iOS, macOS, or both), check whether a UI testing target already exists, and grep for existing `accessibilityIdentifier` usage and launch-argument handling.
2. Interview the user (in Hebrew). You need:
   - **The story**: which 3–6 screens/features sell this app? What is the single strongest "hero" feature? Ask the user to rank them — the order becomes the screenshot order and the video storyline.
   - **Locales** to produce (default: `he` + `en-US`).
   - **Targets**: iOS screenshots? iOS App Preview? Mac screenshots? Mac App Preview? Marketing video for web/social too?
   - Whether the app has (or can have) a demo mode with attractive seeded data.

If the user can't articulate the story, propose one yourself from the project inspection and let them edit it. Don't proceed to Phase 2 without an agreed screen list — everything downstream is built on it.

## Phase 1 — Prepare the app

Three small code changes make the difference between amateur and professional captures. Propose them as a concrete diff/PR for the user's app:

1. **Demo mode**: a `-DemoMode` launch argument that seeds realistic, attractive content (well-written sample documents, sensible dates, populated lists — never empty states or "test test 123"). Demo content must exist in every target locale; Hebrew demo content should be real, natural Hebrew.
2. **Accessibility identifiers** on every element the flow will touch (`.accessibilityIdentifier("newDocumentButton")`). Identifiers are language-independent, so one flow serves all locales.
3. **(Optional but recommended) `-CaptureMode`**: hides badges/timestamps that look stale, disables animations or first-run popovers, and on macOS sets a fixed window size.

## Phase 2 — Script the demo flow

Read `references/xcuitest-flow.md` and write one `DemoFlowTests` XCUITest class for the app. Key principles (details in the reference):

- One flow serves both outputs: `snapshot()`/screenshot calls at each beat for stills, and human-paced execution (`humanPause`, slow typing) so the same run records well as video.
- Beats mirror the agreed story order from Phase 0.
- Locale is injected from outside (`xcodebuild -testLanguage`), never hardcoded.

Show the user the flow and a dry-run plan before capturing.

## Phase 3 — Capture

Use the bundled scripts — don't improvise capture commands, the scripts handle status-bar override, recording lifecycle, and output layout:

- `scripts/capture_ios.sh` — boots the right simulator, applies the clean 9:41 status bar, runs the test per locale, records video, extracts screenshot attachments from the `.xcresult`.
- `scripts/capture_mac.sh` — positions/sizes the app window, captures stills and video of just that window region.

Both scripts print usage with `-h`. Output lands in `AppStoreMedia/<AppName>/<locale>/raw/`. If `fastlane` is already set up in the project, prefer `fastlane snapshot` for the stills and use the script only for video.

## Phase 4 — Convert and verify

Raw captures are almost never at Apple's accepted sizes (e.g. a 6.9" simulator records at 1320×2868 but App Previews must be **886×1920**). Run:

- `scripts/convert_preview.sh` — scales/encodes video to the exact accepted resolution, 30fps, H.264 High@4.0, ~10–12 Mbps, with a valid stereo AAC track (App Store Connect rejects previews with missing/non-conformant audio). Also enforces the 15–30s window and warns if trimming is needed.
- `scripts/verify_assets.py` — checks every file in the output tree against the spec tables and prints a pass/fail report. Run this **before** telling the user the assets are ready.

Requires `ffmpeg` (`brew install ffmpeg`) — the scripts check and say so.

## Phase 5 — Marketing copy and the editing plan

Read `references/marketing-copy.md`, then produce two Hebrew deliverables in `AppStoreMedia/<AppName>/`:

1. **`captions.md`** — for each screenshot, a recommended caption in Hebrew and English (benefit-first, 3–6 words), with placement guidance, plus which framing tool settings to use (RTL alignment for Hebrew!).
2. **`imovie-plan.md`** — a timestamped editing plan for the App Preview: which clip segment goes where, what on-screen text to add at which second, transition and pacing notes, and exact iMovie export settings. The plan must respect Apple's content rules (real app footage only — overlay captions are fine, device frames/hands/marketing montages are not).

These deliverables are where you guide the user on **what text to add and where** — be specific to *their* app and the story from Phase 0, not generic.

## Hard rules (violating these gets the submission rejected)

- App Preview = real, in-app footage only. No device frames, no hands, no lifestyle shots, no pure-marketing intro/outro cards. Short text overlays on top of footage are acceptable.
- Exact accepted resolutions only — see `references/apple-specs.md`. "Close" is rejected.
- 15–30 seconds, ≤30fps, ≤500MB per preview.
- Screenshots may be marketing-styled (frames, backgrounds, captions) but must truthfully depict the app, and must be exact-size.
- Every claim in captions must be true of the shipping app.
- Specs occasionally change. If an upload is rejected on size or the user reports a mismatch, re-check Apple's live pages (linked at the top of `references/apple-specs.md`) before debugging anything else.

## Definition of done

- `verify_assets.py` passes for every locale and device class the user targeted.
- The user has `captions.md` + `imovie-plan.md` in Hebrew.
- Summarize for the user (in Hebrew): what was produced, where it is, the remaining manual steps (iMovie pass, framing tool pass, upload to App Store Connect), and the one-command way to regenerate everything next release.
