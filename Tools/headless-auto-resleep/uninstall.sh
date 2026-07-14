#!/bin/zsh
set -euo pipefail

PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.halftop.headless-auto-resleep.plist"
OLD_PLIST_FILE="$HOME/Library/LaunchAgents/com.eky.headless-auto-resleep.plist"
INSTALL_DIR="$HOME/Library/Application Support/Halftop/Agents/headless-auto-resleep"
ENABLED_DIR="$HOME/Library/Application Support/Halftop/Agents/.enabled"
BACKGROUND_INSTALLER="$(cd "$(dirname "$0")" && pwd)/../Background Service/install.sh"

/bin/launchctl bootout "gui/$(id -u)" "$PLIST_FILE" 2>/dev/null || true
/bin/launchctl bootout "gui/$(id -u)" "$OLD_PLIST_FILE" 2>/dev/null || true
/bin/rm -f "$PLIST_FILE" "$OLD_PLIST_FILE" "$ENABLED_DIR/headless-auto-resleep"
/bin/rm -rf "$INSTALL_DIR"
/bin/rm -rf "$HOME/Library/Application Support/Headless MacBook Tools/Agents/headless-auto-resleep"
"$BACKGROUND_INSTALLER"

echo "Uninstalled."
