# companion-releases

Update host for the **GameCove Companion** app. It serves two small JSON manifests (via
GitHub Pages) and hosts the APKs (via GitHub Releases). Each handheld reads the manifests,
compares versions to what's installed, and updates **only what's behind**.

## How the app uses this repo

| Channel | App fetches | Then |
|---|---|---|
| App self-update | `https://gamecove.github.io/companion-releases/app/latest.json` | downloads the `url` APK, sha256-checks, prompts install |
| Emulator updates | `https://gamecove.github.io/companion-releases/emulators/manifest.json` | per emulator: if blessed > installed, downloads `url`, sha256 + signer check, prompts install |

That base URL is **`updateBaseUrl`** in the app's `lib/config.dart`. If your GitHub account
isn't `gamecove` or the repo isn't `companion-releases`, change it in **both** places:
`lib/config.dart` **and** every `url` in the two manifests (find-and-replace the host).

## Why APKs aren't committed here
RetroArch alone is **175 MB** — over GitHub's 100 MB per-file limit. APKs live in **Releases**
(no size limit), not in the repo. `*.apk` is git-ignored; the repo holds only the manifests,
this README, and the upload script. `emulators/manifest.json` is already filled with the real
package, versionCode, sha256, and signer of each APK in `/Apps` (extracted 2026-06-18); the
`url`s resolve once you run `publish-emulators.sh`.

## One-time setup
```bash
# 1. push this folder as the repo
git init && git add -A && git commit -m "init companion-releases"
git branch -M main
git remote add origin git@github.com:gamecove/companion-releases.git
git push -u origin main

# 2. enable Pages: repo Settings -> Pages -> Deploy from branch -> main / (root)
#    then confirm this loads:
#    https://gamecove.github.io/companion-releases/emulators/manifest.json

# 3. upload the current APKs to Releases (needs `gh`, logged in)
./publish-emulators.sh
#    (different repo: REPO=youracct/yourrepo ./publish-emulators.sh)
```
4. In the **app** repo, set `updateBaseUrl` in `lib/config.dart` to your Pages URL, rebuild the
   Companion APK once (`flutter build apk --release`) — that build is what you preload during
   provisioning, and it now knows where to look.

## Make a NEW emulator release later
1. Drop the new APK in this folder.
2. Get its facts (Android build-tools):
   ```bash
   aapt2 dump badging NEW.apk | grep '^package'      # package + versionCode + versionName
   sha256sum NEW.apk                                  # sha256
   apksigner verify --print-certs NEW.apk             # "Signer #1 ... SHA-256 digest" = signerSha256
   ```
   **The signerSha256 MUST equal the installed build's signer**, or the update fails and a
   forced reinstall **wipes that emulator's saves**. Keep one source/signer per emulator.
3. Cut the release (clean asset name + `<id>-<versionCode>` tag):
   ```bash
   cp NEW.apk /tmp/retroarch.apk
   gh release create retroarch-<newVersionCode> /tmp/retroarch.apk -R gamecove/companion-releases
   ```
4. Edit that emulator's **one** entry in `emulators/manifest.json` — `blessedVersionCode`,
   `versionName`, `url` (new tag), `sha256`, `signerSha256`. Leave every other entry untouched.
   `git commit && git push`.
   → **Only that emulator updates on devices; everything else stays put** (each device compares
   per-app and skips anything already at/above its blessed version).

**Rules:** forward-only (never lower a `blessedVersionCode` — to undo a bad build, publish a
*higher* one); one signer per emulator; `"mandatory": true` only for critical fixes; cores stay
with RetroArch's own updater (app-data is walled off, not shipped here).

## Make a NEW app (Companion) release later
1. Bump `version:` in the app's `pubspec.yaml` (e.g. `1.1.0+10100` — the `+N` is the versionCode).
2. `git tag v1.1.0 && git push origin v1.1.0` → the app repo's `.github/workflows/release.yml`
   builds + publishes `app-release.apk`.
3. Update `app/latest.json` here (served by Pages) with the new `versionCode` / `url` / `sha256`.

## Manifest field reference
```
emulators/manifest.json -> { "emulators": [ {
  id, package, blessedVersionCode, versionName, url, sha256, signerSha256, minAppVersion, mandatory, notes
} ] }
app/latest.json         -> { versionCode, versionName, url, sha256, minSupported, notes }
```

> Guides/promos/QR content is a **separate** repo (`contentBaseUrl` in `lib/config.dart`), not this one.
