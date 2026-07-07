#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
build_dir="$repo_root/.local/build"
stage_dir="$repo_root/.local/dmg_stage"
output_dmg="$repo_root/Klipp.dmg"

cd "$repo_root"

echo "Building production Klipp DMG..."
rm -rf "$build_dir" "$stage_dir" "$output_dmg"

xcodebuild \
  -project Klipp.xcodeproj \
  -scheme Klipp \
  -configuration Release \
  -derivedDataPath "$build_dir" \
  CODE_SIGN_IDENTITY="-"

mkdir -p "$stage_dir"
cp -R "$build_dir/Build/Products/Release/Klipp.app" "$stage_dir/"

if command -v create-dmg >/dev/null 2>&1; then
  if ! create-dmg \
    --volname "Klipp" \
    --window-pos 200 120 \
    --window-size 600 300 \
    --icon-size 100 \
    --icon "Klipp.app" 150 150 \
    --hide-extension "Klipp.app" \
    --app-drop-link 450 150 \
    "$output_dmg" \
    "$stage_dir/"; then
    echo "create-dmg failed; using hdiutil."
    rm -f "$output_dmg"
    ln -s /Applications "$stage_dir/Applications"
    hdiutil create -volname "Klipp" -srcfolder "$stage_dir" -ov -format UDZO "$output_dmg"
  fi
else
  ln -s /Applications "$stage_dir/Applications"
  hdiutil create -volname "Klipp" -srcfolder "$stage_dir" -ov -format UDZO "$output_dmg"
fi

rm -rf "$stage_dir" "$build_dir"

echo "Created $output_dmg"
read -t 5 -p "Closing in 5 seconds (or press Enter to exit immediately)..." || true
echo
