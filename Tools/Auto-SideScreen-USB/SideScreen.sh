#!/bin/bash
set -euo pipefail

# Usage:
#   SideScreen.sh usb
#   SideScreen.sh wireless
#
# Requires macOS Accessibility/Automation permission for the app that runs this
# script: Codex/Terminal/AeroSpace, depending on how you launch it.

mode="${1:-usb}"
case "$mode" in
    usb|wired|cable|kablolu)
        tab_names=("USB" "Wired" "Cable")
        ;;
    wireless|wifi|kablosuz)
        tab_names=("Wireless" "Wi-Fi" "WiFi")
        ;;
    *)
        echo "Usage: $0 usb|wireless" >&2
        exit 64
        ;;
esac

tab_csv=""
for name in "${tab_names[@]}"; do
    [[ -n "$tab_csv" ]] && tab_csv+=","
    tab_csv+="$name"
done

/usr/bin/open -a /Applications/SideScreen.app

/usr/bin/osascript "$tab_csv" <<'APPLESCRIPT'
on splitText(theText, delimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to delimiter
    set theItems to every text item of theText
    set AppleScript's text item delimiters to oldDelimiters
    return theItems
end splitText

on pressElement(theElement)
    tell application "System Events"
        try
            perform action "AXPress" of theElement
        on error
            click theElement
        end try
    end tell
end pressElement

on elementText(theElement)
    tell application "System Events"
        set parts to {}
        try
            set end of parts to name of theElement as text
        end try
        try
            set end of parts to description of theElement as text
        end try
        try
            set end of parts to value of theElement as text
        end try
        return parts
    end tell
end elementText

on pressByName(processName, wantedNames)
    tell application "System Events" to tell process processName
        set allElements to entire contents
        repeat with candidate in allElements
            set texts to my elementText(candidate)
            repeat with t in texts
                repeat with wanted in wantedNames
                    if (t as text) is equal to (wanted as text) then
                        my pressElement(candidate)
                        return true
                    end if
                end repeat
            end repeat
        end repeat
    end tell
    return false
end pressByName

on run argv
    if (count of argv) < 1 then error "missing tab names"
    set tabNames to my splitText(item 1 of argv, ",")
    set processName to "Side Screen"

    tell application "Side Screen" to activate

    tell application "System Events"
        repeat 50 times
            if exists process processName then
                tell process processName
                    if exists window 1 then exit repeat
                end tell
            end if
            delay 0.1
        end repeat
    end tell

    my pressByName(processName, tabNames)
    delay 0.25

    if my pressByName(processName, {"Start", "START"}) is false then
        error "Could not find Side Screen Start button. Grant Accessibility/Automation permission, then try again."
    end if
end run
APPLESCRIPT
