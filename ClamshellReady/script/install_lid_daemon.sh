#!/usr/bin/env bash
set -euo pipefail

APP_LABEL="com.eky.ClamshellReady.LidDaemon"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAEMON_NAME="ClamshellReadyLidDaemon"
INSTALL_PATH="/usr/local/libexec/clamshell-ready-lid-daemon"
PLIST_PATH="/Library/LaunchDaemons/$APP_LABEL.plist"
ALLOWED_UID="$(id -u)"

cd "$ROOT_DIR"
swift build -c release --product "$DAEMON_NAME"
DAEMON_BIN="$(swift build -c release --show-bin-path)/$DAEMON_NAME"

TMP_PLIST="$(mktemp)"
cat > "$TMP_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$APP_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$INSTALL_PATH</string>
    <string>--allowed-uid</string>
    <string>$ALLOWED_UID</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/var/log/clamshell-ready-lid-daemon.log</string>
  <key>StandardErrorPath</key>
  <string>/var/log/clamshell-ready-lid-daemon.log</string>
</dict>
</plist>
PLIST

sudo /bin/mkdir -p /usr/local/libexec
sudo /usr/bin/install -o root -g wheel -m 0755 "$DAEMON_BIN" "$INSTALL_PATH"
sudo /usr/bin/install -o root -g wheel -m 0644 "$TMP_PLIST" "$PLIST_PATH"
rm -f "$TMP_PLIST"

if sudo /bin/launchctl print "system/$APP_LABEL" >/dev/null 2>&1; then
    sudo /bin/launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
fi
sudo /bin/launchctl bootstrap system "$PLIST_PATH"
sudo /bin/launchctl enable "system/$APP_LABEL"

echo "Installed and started $APP_LABEL for uid $ALLOWED_UID"
