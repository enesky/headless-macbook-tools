#!/bin/zsh
set -euo pipefail

PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.halftop.lock-screen-sayer.plist"
OLD_PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.lock-screen-sayer.plist"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/lock-screen-sayer"
ENABLED_DIR="$HOME/Library/Application Support/Halftop/Agents/.enabled"
BACKGROUND_INSTALLER="$(cd "$(dirname "$0")" && pwd)/../Background Service/install.sh"

/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/launchctl bootout "gui/$(id -u)" "$OLD_PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE" "$OLD_PLIST_FILE" "$ENABLED_DIR/lock-screen-sayer"
/bin/rm -rf "$INSTALL_DIR"
/bin/rm -rf "$HOME/Library/Application Support/Headless MacBook Tools/Agents/lock-screen-sayer"
"$BACKGROUND_INSTALLER"

echo "Uninstalled."
