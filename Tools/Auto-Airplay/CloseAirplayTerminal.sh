#!/bin/bash

target_tty="$1"
delay_seconds="${2:-1.0}"

if [[ -z "$target_tty" ]]; then
    exit 0
fi

/bin/sleep "$delay_seconds"

osascript - "$target_tty" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
    set targetTTY to item 1 of argv as text
    tell application "Terminal"
        repeat with w in windows
            repeat with t in tabs of w
                try
                    if (tty of t as text) is targetTTY then
                        close w
                        return
                    end if
                end try
            end repeat
        end repeat
    end tell
end run
APPLESCRIPT
