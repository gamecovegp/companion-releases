#!/usr/bin/env bash
# Upload the emulator APKs in this folder to GitHub Releases on the companion-releases repo,
# using clean asset names + <id>-<versionCode> tags that match emulators/manifest.json.
#
# Requires: GitHub CLI (`gh`) installed and authenticated (`gh auth login`).
# Usage:    ./publish-emulators.sh          (uses REPO below)
#           REPO=youracct/yourrepo ./publish-emulators.sh
set -euo pipefail
REPO="${REPO:-gamecovegp/companion-releases}"
cd "$(dirname "$0")"

# id | source APK filename (in this folder) | versionCode (tag suffix, must match the manifest)
rows=(
  "retroarch|RetroArch_aarch64.apk|1763607214"
  "dolphin|dolphin-2603a.apk|42460"
  "duckstation|DuckStation_0.1-5494_Apkpure.apk|5080"
  "flycast|flycast-2.6.apk|2942"
  "citra|Citra_MMJ_20251112.apk|3932"
  "eden|Eden-Android-v0.2.1-standard.apk|32873047"
  "melonds|Melonds-nightly-release.apk|37"
  "aethersx2|NetherSX2-v2.2n-4248-Turnip-v0.4.apk|15269"
  "ppsspp|PPSSPP - PSP emulator_1.14.4_Apkpure.apk|114040000"
  "m64plusfz|M64Plus FZ Emulator_3.0.328 (beta)-free_Apkpure.apk|328"
  "esde|ES-DE v3.4.1-58.apk|58"
  "steamlink|steamlink-1.3.31.apk|5000313"
)

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for row in "${rows[@]}"; do
  IFS='|' read -r id src vc <<< "$row"
  if [ ! -f "$src" ]; then echo "skip $id: missing '$src'"; continue; fi
  asset="$tmp/$id.apk"
  cp "$src" "$asset"
  tag="$id-$vc"
  echo ">> $id  tag=$tag  ($src)"
  if gh release view "$tag" -R "$REPO" >/dev/null 2>&1; then
    gh release upload "$tag" "$asset" -R "$REPO" --clobber
  else
    gh release create "$tag" "$asset" -R "$REPO" -t "$id $vc" -n "Blessed $id build ($vc)"
  fi
done
echo "Done. Asset URLs follow: https://github.com/$REPO/releases/download/<id>-<versionCode>/<id>.apk"
