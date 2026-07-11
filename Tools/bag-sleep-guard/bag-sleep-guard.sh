#!/bin/zsh
set -u

# ponytail: simplest useful guard; if this false-positives, touch DISABLE_FILE.
DISABLE_FILE="$HOME/.bag-sleep-guard-off"
INPUT_WAIT_SECONDS=5
LOG="$HOME/Library/Logs/bag-sleep-guard.log"

PATH="/usr/bin:/bin:/usr/sbin:/sbin"

[[ -e "$DISABLE_FILE" ]] && exit 0

on_battery() {
  pmset -g batt | grep -q "Battery Power"
}

screen_locked() {
  ioreg -n Root -d1 | grep -Eq '"IOConsoleLocked" = Yes|"CGSSessionScreenIsLocked"=Yes'
}

idle_long_enough() {
  local idle_seconds
  idle_seconds=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF / 1000000000); exit}')
  [[ -n "$idle_seconds" ]] && (( idle_seconds >= INPUT_WAIT_SECONDS ))
}

if on_battery && screen_locked && idle_long_enough; then
  print -r -- "$(date '+%F %T') sleeping: locked + no input for ${INPUT_WAIT_SECONDS}s" >> "$LOG"
  pmset sleepnow
fi
