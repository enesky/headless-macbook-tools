#!/bin/zsh
set -eu

script="${0:A}"
label="com.eky.battery-voice-alert"
bin="$HOME/.local/bin/battery-voice-alert"
plist="$HOME/Library/LaunchAgents/$label.plist"
state_dir="$HOME/Library/Application Support/BatteryVoiceAlert"
state="$state_dir/last-alert"

percent() {
  /usr/bin/pmset -g batt | /usr/bin/awk -F';' '/[0-9]+%/ { sub(/^.*\t/, "", $1); sub(/%$/, "", $1); print $1; exit }'
}

status() {
  /usr/bin/pmset -g batt | /usr/bin/awk -F';' '/[0-9]+%/ { gsub(/^ +| +$/, "", $2); print $2; exit }'
}

bucket() {
  local p="$1"
  if (( p >= 25 )); then
    echo ""
  elif (( p < 10 )); then
    # ponytail: 9 is the "fell below 10" alert; then 8, 6, 4, 2, 1.
    (( p == 9 )) && echo 9 || echo $(( p < 2 ? 1 : (p / 2) * 2 ))
  elif (( p >= 21 )); then
    echo 24
  else
    echo $(( (p / 5) * 5 ))
  fi
}

check() {
  local p s b last
  p="$(percent)"
  s="$(status)"

  if [[ "$s" != "discharging" ]]; then
    /bin/mkdir -p "$state_dir"
    : > "$state"
    exit 0
  fi

  b="$(bucket "$p")"
  [[ -z "$b" ]] && { /bin/mkdir -p "$state_dir"; : > "$state"; exit 0; }

  /bin/mkdir -p "$state_dir"
  last="$(/bin/cat "$state" 2>/dev/null || true)"
  [[ "$last" == "$b" ]] && exit 0

  echo "$b" > "$state"
  /usr/bin/say "Battery low. Please connect the charger."
}

install_agent() {
  /bin/mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
  /bin/cp "$script" "$bin"
  /bin/chmod +x "$bin"
  /bin/cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$bin</string>
    <string>check</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>300</integer>
</dict>
</plist>
PLIST
  /bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$plist" 2>/dev/null || true
  /bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$plist"
  /bin/launchctl enable "gui/$(/usr/bin/id -u)/$label"
  echo "Installed. Test: $bin check"
}

uninstall_agent() {
  /bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$plist" 2>/dev/null || true
  /bin/rm -f "$plist" "$bin"
  echo "Removed."
}

self_test() {
  [[ "$(bucket 100)" == "" ]]
  [[ "$(bucket 25)" == "" ]]
  [[ "$(bucket 24)" == "24" ]]
  [[ "$(bucket 21)" == "24" ]]
  [[ "$(bucket 20)" == "20" ]]
  [[ "$(bucket 19)" == "15" ]]
  [[ "$(bucket 10)" == "10" ]]
  [[ "$(bucket 9)" == "9" ]]
  [[ "$(bucket 8)" == "8" ]]
  [[ "$(bucket 7)" == "6" ]]
  [[ "$(bucket 1)" == "1" ]]
  echo "OK"
}

case "${1:-install}" in
  install) install_agent ;;
  uninstall) uninstall_agent ;;
  check) check ;;
  self-test) self_test ;;
  *) echo "Usage: $0 [install|uninstall|check|self-test]" >&2; exit 2 ;;
esac
