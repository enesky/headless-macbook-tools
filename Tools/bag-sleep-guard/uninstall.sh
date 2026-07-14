#!/bin/zsh
set -eu

LABEL="com.eky.halftop.bag-sleep-guard"
OLD_LABEL="com.eky.bag-sleep-guard"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
OLD_AGENT="$HOME/Library/LaunchAgents/$OLD_LABEL.plist"
ENABLED_DIR="$HOME/Library/Application Support/Halftop/Agents/.enabled"
BACKGROUND_INSTALLER="$(cd "$(dirname "$0")" && pwd)/../Background Service/install.sh"

launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "$OLD_AGENT" 2>/dev/null || true
rm -f "$AGENT" "$OLD_AGENT" "$ENABLED_DIR/bag-sleep-guard"
rm -rf "$HOME/Library/Application Support/Halftop/Agents/bag-sleep-guard"
rm -rf "$HOME/Library/Application Support/Headless MacBook Tools/Agents/bag-sleep-guard"
"$BACKGROUND_INSTALLER"

echo "Uninstalled."
