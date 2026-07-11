#!/bin/zsh
set -eu

LABEL="com.eky.bag-sleep-guard"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)" "$AGENT" 2>/dev/null || true
rm -f "$AGENT"
rm -rf "$HOME/Library/Application Support/Headless MacBook Tools/Agents/bag-sleep-guard"

echo "Uninstalled."
