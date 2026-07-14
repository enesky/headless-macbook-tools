#!/bin/zsh
set -eu

SRC_DIR="${0:A:h}"
SCRIPT_DIR="$HOME/Library/Application Support/Halftop/Agents/bag-sleep-guard"
SHARED_DIR="$HOME/Library/Application Support/Halftop/Agents"
ENABLED_DIR="$SHARED_DIR/.enabled"
BACKGROUND_INSTALLER="$SRC_DIR/../Background Service/install.sh"
AGENT_DIR="$HOME/Library/LaunchAgents"
LABEL="com.eky.halftop.bag-sleep-guard"
OLD_LABEL="com.eky.bag-sleep-guard"
SCRIPT_FILE="$SCRIPT_DIR/Halftop"

mkdir -p "$SCRIPT_DIR" "$ENABLED_DIR" "$AGENT_DIR"
launchctl bootout "gui/$(id -u)" "$AGENT_DIR/$LABEL.plist" 2>/dev/null || true
launchctl bootout "gui/$(id -u)" "$AGENT_DIR/$OLD_LABEL.plist" 2>/dev/null || true
rm -f "$AGENT_DIR/$LABEL.plist" "$AGENT_DIR/$OLD_LABEL.plist"
rm -f "$SCRIPT_DIR/bag-sleep-guard.sh"
rm -rf "$HOME/Library/Application Support/Headless MacBook Tools/Agents/bag-sleep-guard"
cp "$SRC_DIR/bag-sleep-guard.sh" "$SCRIPT_FILE"
chmod +x "$SCRIPT_FILE"
: > "$ENABLED_DIR/bag-sleep-guard"
"$BACKGROUND_INSTALLER"

echo "Installed. Disable temporarily: touch ~/.bag-sleep-guard-off"
echo "Enable again: rm ~/.bag-sleep-guard-off"
