#!/bin/zsh
set -eu

root="$HOME/Library/Application Support/Halftop/Agents"
enabled_dir="$root/.enabled"
launcher="$root/Halftop Background Service"
plist="$HOME/Library/LaunchAgents/com.eky.halftop.background-service.plist"
label="com.eky.halftop.background-service"

/bin/mkdir -p "$root" "$enabled_dir" "$HOME/Library/LaunchAgents"

/bin/cat > "$launcher" <<'LAUNCHER'
#!/bin/zsh
set -eu

root="$HOME/Library/Application Support/Halftop/Agents"
enabled_dir="$root/.enabled"
pids=()

cleanup() {
  for pid in "${pids[@]:-}"; do
    /bin/kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT TERM INT

if [[ -f "$enabled_dir/battery-voice-alert" ]]; then
  (
    while [[ -f "$enabled_dir/battery-voice-alert" ]]; do
      "$root/battery-voice-alert/Halftop" check || true
      /bin/sleep 60
    done
  ) &
  pids+=("$!")
fi

if [[ -f "$enabled_dir/lock-screen-sayer" ]]; then
  "$root/lock-screen-sayer/Halftop" "Lock Screen" &
  pids+=("$!")
fi

if [[ -f "$enabled_dir/headless-auto-resleep" ]]; then
  "$root/headless-auto-resleep/Halftop" &
  pids+=("$!")
fi

if [[ -f "$enabled_dir/bag-sleep-guard" ]]; then
  (
    while [[ -f "$enabled_dir/bag-sleep-guard" ]]; do
      "$root/bag-sleep-guard/Halftop" || true
      /bin/sleep 15
    done
  ) &
  pids+=("$!")
fi

[[ "${#pids[@]}" -eq 0 ]] && exit 0
wait
LAUNCHER
/bin/chmod +x "$launcher"

/bin/cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$launcher</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/halftop-background-service.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/halftop-background-service.err.log</string>
</dict>
</plist>
PLIST

/bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$plist" 2>/dev/null || true
if /bin/ls "$enabled_dir"/* >/dev/null 2>&1; then
  /bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$plist"
  /bin/launchctl enable "gui/$(/usr/bin/id -u)/$label"
fi
