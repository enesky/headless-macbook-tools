#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ClamshellReady"
BUNDLE_ID="com.eky.ClamshellReady"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_MACOS="$APP_BUNDLE/Contents/MacOS"
APP_HELPERS="$APP_BUNDLE/Contents/Library/PrivilegedHelpers"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
cd "$ROOT_DIR"
swift build
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_HELPERS"
cp "$(swift build --show-bin-path)/$APP_NAME" "$APP_MACOS/$APP_NAME"
cp "$(swift build --show-bin-path)/ClamshellReadyLidDaemon" "$APP_HELPERS/ClamshellReadyLidDaemon"
chmod +x "$APP_MACOS/$APP_NAME"
chmod +x "$APP_HELPERS/ClamshellReadyLidDaemon"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"

open_app() { /usr/bin/open -n "$APP_BUNDLE"; }
case "$MODE" in
  run) open_app ;;
  --debug|debug) lldb -- "$APP_MACOS/$APP_NAME" ;;
  --logs|logs) open_app; /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\"" ;;
  --telemetry|telemetry) open_app; /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\"" ;;
  --verify|verify) open_app; sleep 1; pgrep -x "$APP_NAME" >/dev/null ;;
  *) echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
