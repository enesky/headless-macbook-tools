#!/usr/bin/env bash
set -euo pipefail

APP_LABEL="com.eky.ClamshellReady.LidDaemon"
PLIST_PATH="/Library/LaunchDaemons/$APP_LABEL.plist"
INSTALL_PATH="/usr/local/libexec/clamshell-ready-lid-daemon"

sudo /usr/bin/pmset -b disablesleep 0 || true
sudo /bin/launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
sudo /bin/rm -f "$PLIST_PATH" "$INSTALL_PATH" /var/run/clamshell-ready-lid-helper.sock

echo "Uninstalled $APP_LABEL"
