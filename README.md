# Headless MacBook Tools

[English](README.md) | [Türkçe](README.tr.md)

A collection of macOS apps, LaunchAgents, and automation scripts for headless and shortcut-driven MacBook workflows.

This repository consolidates the tools developed in the `MacOS Apps` directory. It keeps installable scripts, small Swift launcher apps, launchd property lists, and SideScreen automation utilities in one place.

## Tools

| Tool | Type | Purpose |
| --- | --- | --- |
| [Auto-Airplay](Auto-Airplay/README.md) | Swift launcher + shell scripts | Finds AirPlay / Screen Mirroring receivers, reads them aloud, and lets you connect using a keyboard selection. |
| [Auto-SideScreen-USB](Auto-SideScreen-USB/README.md) | Swift launcher + UI automation | Starts SideScreen in USB mode with a single shortcut. |
| [Battery Voice Alert](Battery%20Voice%20Alert/README.md) | LaunchAgent script | Announces battery warnings when the MacBook drops below configured thresholds. |
| [Bag Sleep Guard](bag-sleep-guard/README.md) | LaunchAgent script | Puts a closed or bagged MacBook back to sleep when it wakes without user input. |
| [Headless Auto Re-Sleep](headless-auto-resleep/README.md) | Swift helper + installer | Checks display and input state after a headless wake, then returns the Mac to sleep when appropriate. |
| [Lock Screen Sayer](lock-screen-sayer/README.md) | Swift helper + LaunchAgent | Announces when the screen is locked. |
| [SideScreen](SideScreen/README.md) | Open-source macOS + Android app | Uses an Android device as a second display; this version adds automation and auto-connect workflows for headless use. |

## Customized SideScreen

[SideScreen](https://github.com/tranvuongquocdat/SideScreen) is an open-source macOS and Android application. The version included in this repository extends the upstream project with headless-focused automation and auto-connect workflows, including URL-scheme and launch-argument based USB auto-start plus companion launcher and UI automation scripts.

## Repository Scope

The repository includes source code, scripts, property-list examples, documentation, and required project files.

Local build output, caches, and metadata are excluded:

- `.git/`
- `.build/`
- `.clang-module-cache/`
- `.DS_Store`

## Notes

- These tools target macOS.
- UI automation may require permissions under `Privacy & Security > Accessibility` and `Automation`.
- Sleep, screen-lock, AirPlay, and SideScreen behavior can vary by device and macOS version.
- Installation and removal instructions are documented in each tool's README.

## GitHub

[enesky/headless-macbook-tools](https://github.com/enesky/headless-macbook-tools)
