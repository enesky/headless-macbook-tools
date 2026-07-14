#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="$ROOT_DIR/Sources/HeadlessAutoResleep.swift"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/headless-auto-resleep"
SHARED_DIR="$HOME/Library/Application Support/Halftop/Agents"
ENABLED_DIR="$SHARED_DIR/.enabled"
BACKGROUND_INSTALLER="$ROOT_DIR/../Background Service/install.sh"
BINARY_DIR="$INSTALL_DIR"
BINARY_FILE="$BINARY_DIR/Halftop"
OLD_BINARY_FILE="$BINARY_DIR/HeadlessAutoResleep"
LEGACY_INSTALL_DIR="$HOME/Library/Application Support/Headless MacBook Tools/Agents/headless-auto-resleep"
MODULE_CACHE="$HOME/Library/Caches/Halftop/headless-auto-resleep"
LABEL="com.eky.halftop.headless-auto-resleep"
OLD_LABEL="com.eky.headless-auto-resleep"
PLIST_FILE="$HOME/Library/LaunchAgents/$LABEL.plist"
OLD_PLIST_FILE="$HOME/Library/LaunchAgents/$OLD_LABEL.plist"

/bin/mkdir -p "$INSTALL_DIR" "$ENABLED_DIR" "$MODULE_CACHE" "$HOME/Library/LaunchAgents"
/bin/rm -f "$OLD_BINARY_FILE"
/bin/rm -rf "$LEGACY_INSTALL_DIR"
/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/launchctl bootout "gui/$(id -u)" "$OLD_PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE" "$OLD_PLIST_FILE"
SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" \
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
/usr/bin/swiftc "$SOURCE_FILE" -o "$BINARY_FILE"

: > "$ENABLED_DIR/headless-auto-resleep"
"$BACKGROUND_INSTALLER"

echo "Installed. Log: $HOME/Library/Logs/headless-auto-resleep.log"
