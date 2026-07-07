#!/bin/bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
build_dir="$repo_root/.local/screenshot_build"
output="$repo_root/Assets/panel.png"

cd "$repo_root"

echo "Building Klipp (Debug)..."
xcodebuild \
  -project Klipp.xcodeproj \
  -scheme Klipp \
  -configuration Debug \
  -derivedDataPath "$build_dir" \
  CODE_SIGN_IDENTITY="-" \
  -quiet \
  build

app="$build_dir/Build/Products/Debug/Klipp.app"

echo "Rendering screenshot..."
"$app/Contents/MacOS/Klipp" --render-screenshot "$output"

echo "Updated $output"
