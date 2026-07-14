#!/bin/zsh
set -eu

SRC_DIR="${0:A:h}"
SCRIPT_DIR="$HOME/Library/Application Support/Halftop/Agents/bag-sleep-guard"
AGENT_DIR="$HOME/Library/LaunchAgents"
LABEL="com.eky.bag-sleep-guard"

mkdir -p "$SCRIPT_DIR" "$AGENT_DIR"
cp "$SRC_DIR/bag-sleep-guard.sh" "$SCRIPT_DIR/bag-sleep-guard.sh"
chmod +x "$SCRIPT_DIR/bag-sleep-guard.sh"

cat > "$AGENT_DIR/$LABEL.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$SCRIPT_DIR/bag-sleep-guard.sh</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>15</integer>
</dict></plist>
PLIST

launchctl bootout "gui/$(id -u)" "$AGENT_DIR/$LABEL.plist" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT_DIR/$LABEL.plist"
launchctl enable "gui/$(id -u)/$LABEL"

echo "Installed. Disable temporarily: touch ~/.bag-sleep-guard-off"
echo "Enable again: rm ~/.bag-sleep-guard-off"
