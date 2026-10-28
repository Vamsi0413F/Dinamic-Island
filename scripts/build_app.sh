#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "==> Building MacDynamicIsland (Release)..."
swift build -c release

BIN_PATH="$PROJECT_DIR/.build/release/MacDynamicIsland"
if [ ! -f "$BIN_PATH" ]; then
    # In some SPM versions with custom cache/output paths
    BIN_PATH=$(swift build -c release --show-bin-path)/MacDynamicIsland
fi

APP_DIR="$PROJECT_DIR/build/MacDynamicIsland.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Packaging into $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/MacDynamicIsland"
chmod +x "$MACOS_DIR/MacDynamicIsland"

if [ -f "$PROJECT_DIR/Resources/Info.plist" ]; then
    cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
fi

echo "==> Signing application bundle (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Successfully created MacDynamicIsland.app at:"
echo "    $APP_DIR"
