#!/usr/bin/env bash
# Builds FileDrop.app in one step: release build, fresh app icon, app bundle.
#
# Usage: ./build.sh [--run]
#   --run   launch the built app afterwards

set -euo pipefail

APP_NAME="FileDrop"
BUNDLE_ID="com.wundi77.FileDrop"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "→ Baue $APP_NAME (Release)…"
swift build -c release --package-path "$ROOT_DIR"
BIN_PATH="$(swift build -c release --package-path "$ROOT_DIR" --show-bin-path)/$APP_NAME"

echo "→ Baue App-Icon…"
mkdir -p "$BUILD_DIR"
iconutil -c icns "$ROOT_DIR/Resources/AppIcon.iconset" -o "$BUILD_DIR/AppIcon.icns"

echo "→ Baue App-Bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
cp "$BUILD_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "→ Signiere App (ad-hoc)…"
codesign --force --deep --sign - "$APP_BUNDLE"

# Let Finder/Dock pick up the new icon immediately.
touch "$APP_BUNDLE"

echo "✓ Fertig: $APP_BUNDLE"
open -R "$APP_BUNDLE"

if [[ "${1:-}" == "--run" ]]; then
    echo "→ Starte $APP_NAME…"
    open "$APP_BUNDLE"
fi
