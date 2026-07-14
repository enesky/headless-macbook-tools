#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$ROOT_DIR/Sources/LockScreenSayer.swift"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/lock-screen-sayer"
BINARY_FILE="$INSTALL_DIR/LockScreenSayer"
MODULE_CACHE="$HOME/Library/Caches/Halftop/lock-screen-sayer"
PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.lock-screen-sayer.plist"
PHRASE="${1:-Lock Screen}"

/bin/mkdir -p "$INSTALL_DIR" "$MODULE_CACHE"
SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
/usr/bin/swiftc "$SOURCE_FILE" -o "$BINARY_FILE"

/bin/mkdir -p "$HOME/Library/LaunchAgents"

/bin/cat > "$PLIST_FILE" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.eky.lock-screen-sayer</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_FILE</string>
        <string>$PHRASE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/lock-screen-sayer.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/lock-screen-sayer.err.log</string>
</dict>
</plist>
PLIST

/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/launchctl bootstrap "gui/$(id -u)" "$PLIST_FILE"
/bin/launchctl enable "gui/$(id -u)/com.eky.lock-screen-sayer"

echo "Installed. Lock your screen to test it."
