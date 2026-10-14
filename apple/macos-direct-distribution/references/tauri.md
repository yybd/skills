# Sparkle in a Tauri app (no Xcode project)

The main workflow of this skill assumes an Xcode target. A Tauri app has no
macOS `.xcodeproj`: `tauri build` produces the signed `.app` and `.dmg` itself.
Steps 1–5 (create a Direct target, add the SPM dependency, write Swift) do not
apply. Everything from **step 6 (ship a release)** onward does, unchanged —
`stage_release.sh` and `make_appcast.sh` operate on a finished DMG.

What replaces steps 1–5 is below. Verified end to end on Tauri 2.11 with
Sparkle 2.9.3, notarization Accepted.

## 1. Vendor the framework

There is no SPM to resolve, so the framework is committed to the repo:

```bash
mkdir -p src-tauri/frameworks
cp -R <Sparkle.xcframework>/macos-arm64_x86_64/Sparkle.framework src-tauri/frameworks/
```

An existing checkout usually already has one:

```bash
find ~/Library/Developer/Xcode/DerivedData -path "*artifacts/sparkle/Sparkle/Sparkle.xcframework" | head -1
```

Tell the bundler to embed it, and merge in the Sparkle keys, in
`src-tauri/tauri.conf.json`:

```json
"macOS": {
  "signingIdentity": "Developer ID Application: … (TEAMID)",
  "hardenedRuntime": true,
  "frameworks": ["frameworks/Sparkle.framework"],
  "infoPlist": "Info.macos.plist"
}
```

`Info.macos.plist` holds `SUFeedURL` and `SUPublicEDKey` exactly as the Xcode
path would.

## 2. Re-sign Sparkle BEFORE building — the notarization trap

Sparkle ships **ad-hoc signed** (`Signature=adhoc`, `TeamIdentifier=not set`),
and a bundler that signs only the outer `.app` leaves its nested helpers that
way. Notarization then comes back `Invalid`:

```
.../Sparkle.framework/Versions/B/Updater.app/Contents/MacOS/Updater
  "The binary is not signed with a valid Developer ID certificate."
  "The signature does not include a secure timestamp."
```

`codesign --verify --deep --strict` on the built app passes anyway — an ad-hoc
signature is structurally valid — so this is only caught by submitting. Re-sign
the vendored framework innermost-first (a bundle's signature seals its
contents, so any child signed afterwards invalidates its parent), with
`--timestamp` and `--options runtime`:

```
XPCServices/*.xpc  →  Updater.app  →  Autoupdate  →  Sparkle.framework
```

Do it on the copy under `src-tauri/frameworks` so it lands in every build.
Tauri 2.11 does deep-sign what it embeds, but it signs *what it is given*: the
ad-hoc nested binaries are re-signed by it only at the levels it walks, and
relying on that is what produced the rejection above.

Check with:

```bash
codesign -dvv .../Sparkle.framework/Versions/B/Updater.app 2>&1 | grep Authority
```

`Signature=adhoc` means it will be rejected.

## 3. Drive Sparkle from Rust

Sparkle has no Rust bindings; go through the ObjC runtime with `objc2` (already
an Apple-platform dependency in most Tauri apps). Two selectors are enough:

- `[[SPUStandardUpdaterController alloc] initWithStartingUpdater:YES updaterDelegate:nil userDriverDelegate:nil]`
  at startup — **keep the returned object alive** (a `OnceLock`), or scheduled
  checks stop when it drops.
- `-checkForUpdates:` from a "Check for Updates…" menu item.

`AnyClass::get(c"SPUStandardUpdaterController")` returning `None` means the
framework isn't in the bundle — degrade to a no-op so `cargo run` still works.
Init-family messages need an `Allocated<AnyObject>` receiver in objc2 0.6.

Handle the menu item **natively** and return before forwarding it to the
webview: Sparkle owns its own UI.

## 4. Link it

In `build.rs`:

```rust
if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos") {
    println!("cargo:rustc-link-search=framework={frameworks}");
    println!("cargo:rustc-link-lib=framework=Sparkle");
    println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path/../Frameworks");
}
```

Two traps:

- **Gate on `CARGO_CFG_TARGET_OS`, not `cfg!(target_os)`.** A build script is
  compiled for the *host*, so `cfg!(target_os = "macos")` is true while
  cross-compiling to iOS, and the iOS link then fails with "building for
  'iOS-simulator', but linking in dylib built for 'macOS'".
- Add an rpath to the source `frameworks/` dir for `cargo run` **only in debug**
  (`PROFILE == "debug"`). In release it bakes an absolute path from the build
  machine into the shipped binary.

## 5. Release

`tauri build` emits the signed DMG, so skip the archive/export half of
**notarize-and-distribute** and go straight to `notarytool submit` + `stapler`,
then `stage_release.sh`. Two things that bite:

- **Stale bundles.** Renaming the app leaves old `.app`s in
  `target/release/bundle/macos/`; pick the newest, not the first, or a stale
  build gets notarized.
- **Leftover mounts.** An interrupted run leaves `/Volumes/dmg.*` attached and
  the next DMG build fails; `hdiutil detach` them first.

A working end-to-end script lives in the quickMD project at
`scripts/release-macos.sh` (build → sign Sparkle → build → verify → notarize →
staple → stage → R2).
