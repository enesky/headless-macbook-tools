#!/bin/zsh
set -euo pipefail

PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.headless-auto-resleep.plist"
INSTALL_DIR="$HOME/Library/Application Support/Headless MacBook Tools/Agents/headless-auto-resleep"

/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE"
/bin/rm -rf "$INSTALL_DIR"

echo "Uninstalled."
