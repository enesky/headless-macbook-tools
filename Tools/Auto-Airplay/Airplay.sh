#!/bin/bash

# Discover devices, speak the list, press a number key (no Enter) to connect.

script_dir=$(cd "$(dirname "$0")" && pwd)
DEVICE_FILE="$HOME/.airplay_devices"
connect_script="$script_dir/ConnectAirplay.sh"
picker_script="$script_dir/PickAirplayDevice.sh"

play_error_sound() {
    /usr/bin/afplay -t 0.2 /System/Library/Sounds/Sosumi.aiff >/dev/null 2>&1 || true
}

open_terminal_command() {
    local command_body="$1"
    local command_file
    command_file="$(/usr/bin/mktemp /tmp/auto-airplay-terminal.XXXXXX.command)" || return 1
    {
        printf '#!/bin/bash\n'
        printf '%s\n' "$command_body"
    } > "$command_file"
    chmod +x "$command_file"
    /usr/bin/open -a Terminal "$command_file"
}

show_discovery_error() {
    local message="${1:-No screen mirroring devices available.}"
    play_error_sound
    printf '%s\n' "$message" >&2
    /usr/bin/say "No AirPlay devices found." >/dev/null 2>&1
    play_error_sound
}

discovery_output="$("$script_dir/ListAirplayDevices.sh" --list-only 2>&1)"
discovery_status=$?
if (( discovery_status != 0 )); then
    show_discovery_error "${discovery_output:-No screen mirroring devices available.}"
    exit "$discovery_status"
fi

names=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    names+=("${line#*|}")
done < "$DEVICE_FILE"

if [[ ${#names[@]} -eq 0 ]]; then
    echo "No devices in list."
    exit 1
fi

list_output=''
for i in "${!names[@]}"; do
    list_output+=$(printf '  %d) %s\n' "$((i + 1))" "${names[i]}")
done
exit_choice=$((${#names[@]} + 1))
list_output+=$(printf '  %d) Exit\n' "$exit_choice")
list_output+=$'\n'

(
    last=$((${#names[@]} - 1))
    for i in "${!names[@]}"; do
        say "$((i + 1)), ${names[i]}." &
        wait $!
        (( i < last )) && sleep 0.05
    done
    say "$exit_choice, Exit." &
    wait $!
) &
say_job=$!

stop_speaking() {
    [[ -n "${say_job:-}" ]] || return
    kill -TERM "$say_job" 2>/dev/null
    pkill -P "$say_job" 2>/dev/null
    pkill -x say 2>/dev/null
    wait "$say_job" 2>/dev/null
}

if [[ -t 0 ]]; then
    exec "$picker_script"
else
    printf -v terminal_inner 'exec %q' "$picker_script"
    if ! open_terminal_command "$terminal_inner"; then
        printf '%s\n' "Could not open Terminal." >&2
        play_error_sound
        exit 1
    fi
    exit 0
fi
