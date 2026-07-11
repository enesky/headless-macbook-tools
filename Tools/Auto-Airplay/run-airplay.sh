#!/usr/bin/env bash
set -u

# Starts the headless AirPlay screen mirror flow without AeroSpace.
# Override AIRPLAY_REPO_DIR if the scripts are not next to this launcher.

CONSOLE_USER="$(/usr/bin/stat -f '%Su' /dev/console 2>/dev/null || true)"
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
  REAL_HOME="$(/usr/bin/dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
elif [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
  REAL_HOME="$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
else
  REAL_HOME="$HOME"
fi
REAL_HOME="${REAL_HOME:-$HOME}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AIRPLAY_REPO_DIR="${AIRPLAY_REPO_DIR:-$SCRIPT_DIR}"
AIRPLAY_ENTRYPOINT="${AIRPLAY_ENTRYPOINT:-Airplay.sh}"
SOUND_FILE="${AIRPLAY_BEEP_SOUND:-/System/Library/Sounds/Funk.aiff}"
BEEP_DURATION_SECONDS="${AIRPLAY_BEEP_DURATION_SECONDS:-0.07}"
MODE="${1:-run}"

log() {
  printf '%s\n' "$*" >&2
}

fail() {
  log "ERROR: $*"
  say_error "$*"
  exit 1
}

say_error() {
  local message="$1"
  if command -v say >/dev/null 2>&1; then
    /usr/bin/say "AirPlay error" >/dev/null 2>&1 &
  fi
  if [[ -r /System/Library/Sounds/Sosumi.aiff ]]; then
    (
      /usr/bin/afplay -t 0.2 /System/Library/Sounds/Sosumi.aiff >/dev/null 2>&1
      /bin/sleep 0.08
      /usr/bin/afplay -t 0.2 /System/Library/Sounds/Sosumi.aiff >/dev/null 2>&1
    ) &
  fi
  log "$message"
}

play_beep() {
  if [[ -r "$SOUND_FILE" ]]; then
    /usr/bin/afplay -t "$BEEP_DURATION_SECONDS" "$SOUND_FILE" >/dev/null 2>&1
  else
    printf '\a'
  fi
}

beep_ready() {
  play_beep
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Required file not found: $path"
}

[[ -d "$AIRPLAY_REPO_DIR" ]] || fail "Repo folder not found: $AIRPLAY_REPO_DIR. Clone it or set AIRPLAY_REPO_DIR."

require_file "$AIRPLAY_REPO_DIR/$AIRPLAY_ENTRYPOINT"
require_file "$AIRPLAY_REPO_DIR/ListAirplayDevices.sh"
require_file "$AIRPLAY_REPO_DIR/ConnectAirplay.sh"

chmod +x \
  "$AIRPLAY_REPO_DIR/$AIRPLAY_ENTRYPOINT" \
  "$AIRPLAY_REPO_DIR/ListAirplayDevices.sh" \
  "$AIRPLAY_REPO_DIR/ConnectAirplay.sh" \
  || fail "Could not mark AirPlay scripts executable. Check file permissions in $AIRPLAY_REPO_DIR."

if [[ "$MODE" == "--preflight" ]]; then
  log "OK: Repo folder found: $AIRPLAY_REPO_DIR"
  log "OK: Required scripts exist and are executable."
  exit 0
fi

if [[ "$MODE" == "--beep-only" ]]; then
  beep_ready
  exit 0
fi

if [[ "$MODE" != "run" ]]; then
  fail "Unknown option: $MODE. Use no option, --preflight, or --beep-only."
fi

beep_ready

cd "$AIRPLAY_REPO_DIR" || fail "Could not enter repo folder: $AIRPLAY_REPO_DIR"

log "Starting AirPlay flow from: $AIRPLAY_REPO_DIR/$AIRPLAY_ENTRYPOINT"
exec "/bin/bash" "$AIRPLAY_REPO_DIR/$AIRPLAY_ENTRYPOINT"
