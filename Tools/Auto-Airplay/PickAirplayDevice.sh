#!/bin/bash

script_dir=$(cd "$(dirname "$0")" && pwd)
DEVICE_FILE="$HOME/.airplay_devices"
connect_script="$script_dir/ConnectAirplay.sh"
close_terminal_script="$script_dir/CloseAirplayTerminal.sh"

stop_speaking() {
    pkill -x say 2>/dev/null
}

close_this_terminal() {
    local tty_path="${1:-}"
    [[ -n "$tty_path" ]] || return
    nohup "$close_terminal_script" "$tty_path" >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

names=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    names+=("${line#*|}")
done < "$DEVICE_FILE"

if [[ ${#names[@]} -eq 0 ]]; then
    echo "No devices in list."
    exit 1
fi

exit_choice=$((${#names[@]} + 1))

print_menu() {
    clear
    for i in "${!names[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${names[i]}"
    done
    printf '  %d) Exit\n\n' "$exit_choice"
}

airplay_tty="$(tty 2>/dev/null || true)"

while true; do
    print_menu
    read -rsn1 -p "Choose device (1-$exit_choice), press a number: " choice </dev/tty || {
        stop_speaking
        close_this_terminal "$airplay_tty"
        exit 1
    }
    printf '\n'

    stop_speaking

    if [[ -z "$choice" || "$choice" == $'\e' ]]; then
        continue
    fi

    if [[ "$choice" == "$exit_choice" ]]; then
        close_this_terminal "$airplay_tty"
        exit 0
    fi

    if [[ "$choice" =~ ^[1-9]$ ]] && (( choice <= ${#names[@]} )); then
        "$connect_script" "$choice"
        ec=$?
        close_this_terminal "$airplay_tty"
        exit "$ec"
    fi

    printf 'Invalid choice: %s\n' "$choice"
    /bin/sleep 1
done
