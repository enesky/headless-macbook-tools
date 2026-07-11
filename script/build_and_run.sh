#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="HeadlessMacBookTools"
BUNDLE_ID="com.eky.HeadlessMacBookTools"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.clang-module-cache"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
cd "$ROOT_DIR"
swift build
BIN_DIR="$(swift build --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources" "$CONTENTS/Library/PrivilegedHelpers"
cp "$BIN_DIR/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"
cp "$BIN_DIR/ClamshellReadyLidDaemon" "$CONTENTS/Library/PrivilegedHelpers/ClamshellReadyLidDaemon"
cp -R "$ROOT_DIR/Tools" "$CONTENTS/Resources/Tools"
cp "$ROOT_DIR/Assets/MenuBar/headless-menu-iconTemplate.png" "$CONTENTS/Resources/"
cp "$ROOT_DIR/Assets/MenuBar/headless-menu-iconTemplate@2x.png" "$CONTENTS/Resources/"
chmod +x "$CONTENTS/MacOS/$APP_NAME" "$CONTENTS/Library/PrivilegedHelpers/ClamshellReadyLidDaemon"
find "$CONTENTS/Resources/Tools" -type f \( -name '*.sh' -o -name '*.command' \) -exec chmod +x {} +

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>Headless MacBook Tools</string>
  <key>CFBundleDisplayName</key><string>Headless MacBook Tools</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>CFBundleURLTypes</key><array><dict>
    <key>CFBundleURLName</key><string>$BUNDLE_ID.actions</string>
    <key>CFBundleURLSchemes</key><array><string>headlesstools</string></array>
  </dict></array>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null

open_app() { /usr/bin/open -n "$APP_BUNDLE"; }

case "$MODE" in
  run) open_app ;;
  --debug|debug) lldb -- "$CONTENTS/MacOS/$APP_NAME" ;;
  --logs|logs) open_app; /usr/bin/log stream --info --style compact --predicate "process == '$APP_NAME'" ;;
  --telemetry|telemetry) open_app; /usr/bin/log stream --info --style compact --predicate "subsystem == '$BUNDLE_ID'" ;;
  --verify|verify) open_app; sleep 2; pgrep -x "$APP_NAME" >/dev/null; echo "OK: $APP_NAME is running" ;;
  *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
