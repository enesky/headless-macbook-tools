#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$ROOT_DIR/Sources/LockScreenSayer.swift"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/lock-screen-sayer"
SHARED_DIR="$HOME/Library/Application Support/Halftop/Agents"
ENABLED_DIR="$SHARED_DIR/.enabled"
BACKGROUND_INSTALLER="$ROOT_DIR/../Background Service/install.sh"
BINARY_FILE="$INSTALL_DIR/Halftop"
OLD_BINARY_FILE="$INSTALL_DIR/LockScreenSayer"
LEGACY_INSTALL_DIR="$HOME/Library/Application Support/Headless MacBook Tools/Agents/lock-screen-sayer"
MODULE_CACHE="$HOME/Library/Caches/Halftop/lock-screen-sayer"
LABEL="com.eky.halftop.lock-screen-sayer"
OLD_LABEL="com.eky.lock-screen-sayer"
PLIST_FILE="$HOME/Library/LaunchAgents/$LABEL.plist"
OLD_PLIST_FILE="$HOME/Library/LaunchAgents/$OLD_LABEL.plist"
PHRASE="${1:-Lock Screen}"

/bin/mkdir -p "$INSTALL_DIR" "$ENABLED_DIR" "$MODULE_CACHE"
/bin/rm -f "$OLD_BINARY_FILE"
/bin/rm -rf "$LEGACY_INSTALL_DIR"
/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/launchctl bootout "gui/$(id -u)" "$OLD_PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE" "$OLD_PLIST_FILE"
SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
/usr/bin/swiftc "$SOURCE_FILE" -o "$BINARY_FILE"

: > "$ENABLED_DIR/lock-screen-sayer"
"$BACKGROUND_INSTALLER"

echo "Installed. Lock your screen to test it."
