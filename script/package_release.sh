#!/usr/bin/env bash
set -euo pipefail

VERSION_TAG="${1:-${GITHUB_REF_NAME:-v0.3.1}}"
VERSION="${VERSION_TAG#v}"
APP_NAME="Halftop"
EXECUTABLE_NAME="Halftop"
BUNDLE_ID="com.eky.halftop"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
ZIP_PATH="$DIST_DIR/Halftop-$VERSION_TAG.zip"

export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.clang-module-cache"
export COPYFILE_DISABLE=1

cd "$ROOT_DIR"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_BUNDLE" "$ZIP_PATH"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Library/PrivilegedHelpers"
cp "$BIN_DIR/$EXECUTABLE_NAME" "$CONTENTS/MacOS/$EXECUTABLE_NAME"
cp "$BIN_DIR/HalftopLidDaemon" "$CONTENTS/Library/PrivilegedHelpers/Halftop Privileged Helper"
cp -R "$ROOT_DIR/Tools" "$CONTENTS/Resources/Tools"
cp "$ROOT_DIR/Assets/MenuBar/halftop-menu-iconTemplate.png" "$CONTENTS/Resources/"
cp "$ROOT_DIR/Assets/MenuBar/halftop-menu-iconTemplate@2x.png" "$CONTENTS/Resources/"
cp "$ROOT_DIR/Assets/Halftop.icns" "$CONTENTS/Resources/"
chmod +x "$CONTENTS/MacOS/$EXECUTABLE_NAME" "$CONTENTS/Library/PrivilegedHelpers/Halftop Privileged Helper"
find "$CONTENTS/Resources/Tools" -type f \( -name '*.sh' -o -name '*.command' \) -exec chmod +x {} +

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>Halftop.icns</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSAppleEventsUsageDescription</key><string>Halftop uses System Events to control Screen Mirroring.</string>
  <key>CFBundleURLTypes</key><array><dict>
    <key>CFBundleURLName</key><string>$BUNDLE_ID.actions</string>
    <key>CFBundleURLSchemes</key><array><string>halftop</string></array>
  </dict></array>
</dict></plist>
PLIST

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null
else
  codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE" >/dev/null
fi
codesign --verify --deep --strict "$APP_BUNDLE"
(
  cd "$DIST_DIR"
  zip -qry -X "$ZIP_PATH" "$APP_NAME.app"
)
echo "$ZIP_PATH"
