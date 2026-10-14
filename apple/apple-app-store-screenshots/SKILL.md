---
name: apple-app-store-screenshots
description: Convert any image into a screenshot that complies with Apple App Store Connect specifications for iPhone, iPad, Mac, Apple TV, Apple Watch, or Apple Vision Pro. Use whenever the user wants to prepare, format, resize, or fix a screenshot for App Store submission, App Store Connect upload, TestFlight, or an Apple app listing — even if they only say things like "make this image the right size for the App Store", "Apple rejected my screenshot", "format for App Store", or "fit my screenshot to Apple's requirements". Also use when the user mentions a specific Apple device size (e.g. "1290x2796", "6.9 inch display", "Mac App Store screenshot") and wants an image conformed to it. The skill handles aspect-ratio mismatches by asking the user how to fit the content (padded background, blur, stretch, or crop) instead of silently distorting the image. This skill only CONFORMS an image that already exists to exact pixel dimensions — to capture screenshots or an App Preview video from a running app via a scripted demo flow use the `appstore-media` skill, and to organize/validate/upload the listing's screenshot files use the `app-store-metadata` skill.
---

# Apple App Store screenshot formatter

> **Conversational language:** talk to the user — questions, summaries, reports — in the `conversational language` set in the hub `DATA.md` (`~/Developer/app-hub/DATA.md`; currently `hebrew`); fall back to the language the user writes in if it is unset (e.g. a standalone project with no hub). This sets the *conversation* language only — content/deliverables follow the app's target locales.

This skill turns an arbitrary image into a PNG that meets Apple's App Store Connect screenshot specifications. App Review rejects screenshots that are not exactly one of the accepted sizes for the target device, so the goal is to produce a file with **the exact pixel dimensions Apple expects**, in PNG or JPG, RGB (no alpha), with the original content presented sensibly when the aspect ratios do not match.

## Conversation flow

There are three things the skill needs from the user before it can produce a file. Some of them may already be answered in the conversation — only ask about what is still unknown.

1. **Which file?** The source image. If the user did not name a file, ask. Accept absolute paths, paths inside the workspace folder, or names of recently-mentioned files. If the user has attached an image to the conversation, treat that as a strong default and confirm.
2. **Which target?** Device family and exact size. Use `references/apple-sizes.md` to present the options. Default suggestions:
   - If the source is landscape and ≥ 1280px wide: suggest **Mac**.
   - If the source aspect ratio is portrait and close to 19.5:9: suggest the latest **iPhone 6.9"** size.
   - If the source aspect ratio is close to 4:3 or 3:4: suggest **iPad 13"**.
   - Otherwise, ask.
   Once the device is chosen, pick the orientation that requires the smallest amount of re-canvasing relative to the source.
3. **How to fit the content?** Only ask this if the source aspect ratio does not already match the target. Offer these modes:
   - **pad-white** — letterbox on a white background. Safest, most neutral.
   - **pad-black** — letterbox on a black background. Good for dark-mode apps.
   - **pad-color** — letterbox on a user-supplied hex color.
   - **blur** — letterbox on a blurred, enlarged copy of the source. Looks polished but de-emphasizes the original content's edges.
   - **stretch** — fill the canvas by distorting the image. Almost always wrong; offer it but warn that proportions will be off.
   - **crop** — fill the canvas by cropping (center-crop). Loses content at the edges.

Use `AskUserQuestion` for these choices rather than free-form prompts — the user gets a clean picker and the skill stays consistent across runs.

## Producing the output

Use the bundled script `scripts/format_screenshot.py`. It handles resizing, the six fit modes, flattening alpha against the chosen background, and writing the PNG. Call it once the answers above are settled:

```bash
python3 scripts/format_screenshot.py \
  --input "<path to source image>" \
  --width <W> --height <H> \
  --fit <pad-white|pad-black|pad-color|blur|stretch|crop> \
  [--bg-color "#RRGGBB"] \
  --output "<destination path>"
```

The script validates that the output is exactly `W×H`, PNG, mode `RGB`, then prints a one-line confirmation with the final size and file path. If the script fails (missing Pillow, unreadable input, etc.), fix it and rerun — do not silently substitute another approach.

### Where to save the file

Always create a sub-folder named **`app-store-screenshots/`** next to the source file and write into it. Name the output `<original-stem>-<W>x<H>.png`. Example: `~/Desktop/login.png` → `~/Desktop/app-store-screenshots/login-2880x1800.png`. If `app-store-screenshots/` already exists, reuse it.

If the source file is somewhere the user clearly does not want polluted (e.g. read-only uploads), fall back to a writable location (the current working directory, or `/tmp`) and tell the user the exact path where the file ended up.

## After the file is written

1. Read the output with the `Read` tool so the user (and you) can confirm visually that it looks right.
2. Report the absolute output path so the user can open it (clients that linkify paths will make it clickable).
3. Briefly state the final dimensions and which Apple device family the file is valid for. No long postamble.

If the user asks for multiple sizes (e.g. "all Mac sizes") loop the script per size and present all the resulting files together at the end.

## Why each step matters

- **Exact pixels, not "approximately right":** App Store Connect rejects uploads that are off by even one pixel from the published sizes, so the script verifies dimensions after writing — never trust that resize math succeeded without checking.
- **No alpha channel:** Apple expects flat PNG/JPG. Source PNGs often carry transparency that would render as black on iOS. The script always flattens against the chosen background.
- **Asking about fit:** Distorting a portrait phone screenshot into a Mac landscape frame produces visibly wrong proportions and gets rejected during App Review for "image does not represent app". Asking is faster than guessing wrong and redoing.
- **Per-file folder vs. flat dump:** Users typically prepare a batch of screenshots for one submission. Grouping by `app-store-screenshots/` keeps the upload set together without renaming every file.

## Reference

`references/apple-sizes.md` is the full table of valid dimensions per device family, copied from Apple's published screenshot specifications. Read it whenever the user picks a device, or when you need to validate that a size the user typed is actually accepted.
