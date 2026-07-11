#!/bin/bash

# MacOS 15.7.4 Sequoia - Connect to an AirPlay device by number
# Reads device mapping from ~/.airplay_devices (written by ListAirplayDevices.sh)

DEVICE_FILE="$HOME/.airplay_devices"
choice="$1"

if [[ -z "$choice" ]]; then
    echo "Usage: ConnectAirplay.sh <number>"
    exit 1
fi

if [[ ! -f "$DEVICE_FILE" ]]; then
    echo "No device list found. Run ListAirplayDevices.sh first."
    exit 1
fi

devices=()
names=()
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    devices+=("${line%%|*}")
    names+=("${line#*|}")
done < "$DEVICE_FILE"

if (( choice < 1 || choice > ${#devices[@]} )); then
    echo "Invalid choice: $choice (1-${#devices[@]})"
    exit 1
fi

chosen_id="${devices[$((choice - 1))]}"
chosen_name="${names[$((choice - 1))]}"

say "Connecting to $chosen_name" &
SUCCESS_SOUND="/System/Library/Sounds/Hero.aiff"
ERROR_SOUND="/System/Library/Sounds/Sosumi.aiff"

play_error_sound() {
    [[ -r "$ERROR_SOUND" ]] || return
    afplay -t 0.2 "$ERROR_SOUND" >/dev/null 2>&1
    sleep 0.08
    afplay -t 0.2 "$ERROR_SOUND" >/dev/null 2>&1
}

# Must match ListAirplayDevices.sh: scroll, then every checkbox of sa + every checkbox of each group.
# Only checking checkbox 1 of each group misses devices listed as other checkboxes in the same group.
script_tmp=$(mktemp)
trap 'rm -f "$script_tmp"' EXIT
cat > "$script_tmp" <<'APPLESCRIPT'
on run argv
    if (count of argv) is 0 then error "missing AX id"
    set chosenId to item 1 of argv as text
    tell application "System Events" to tell process "Control Center"
        if not (exists window "Control Center") then
            repeat with menuBarItem in every menu bar item of menu bar 1
                if description of menuBarItem as text is "Screen Mirroring" then
                    click menuBarItem
                    exit repeat
                end if
            end repeat
            delay 1.5
        end if
        set sa to scroll area 1 of group 1 of window "Control Center"
        try
            repeat with sb in every scroll bar of sa
                set value of sb to minimum value of sb
            end repeat
        end try
        delay 0.2
        try
            repeat with sb in every scroll bar of sa
                set value of sb to maximum value of sb
            end repeat
        end try
        delay 0.5
        try
            repeat with cb in every checkbox of sa
                try
                    set axId to value of attribute "AXIdentifier" of cb as text
                    if axId is equal to chosenId then
                        click cb
                        delay 0.3
                        click (first menu bar item of menu bar 1 whose description is "Screen Mirroring")
                        return
                    end if
                end try
            end repeat
        end try
        repeat with g in every group of sa
            repeat with cb in every checkbox of g
                try
                    set axId to value of attribute "AXIdentifier" of cb as text
                    if axId is equal to chosenId then
                        click cb
                        delay 0.3
                        click (first menu bar item of menu bar 1 whose description is "Screen Mirroring")
                        return
                    end if
                end try
            end repeat
        end repeat
        error "no checkbox matched id"
    end tell
end run
APPLESCRIPT

if ! osascript "$script_tmp" "$chosen_id"; then
    play_error_sound &
    echo "Could not find that device in Screen Mirroring (list may be stale). Run ListAirplayDevices.sh again." >&2
    exit 1
fi

[[ -r "$SUCCESS_SOUND" ]] && afplay -t 0.2 "$SUCCESS_SOUND" >/dev/null 2>&1 &
