#!/bin/zsh
set -euo pipefail

PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.lock-screen-sayer.plist"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/lock-screen-sayer"

/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE"
/bin/rm -rf "$INSTALL_DIR"

echo "Uninstalled."
