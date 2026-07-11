# Headless MacBook Tools

A menu-bar-only macOS utility that collects the headless MacBook workflows in one native SwiftUI app.

## Features

- Clamshell readiness based on physical external-display and power-adapter state
- Optional battery operation and experimental lid-close override
- AirPlay display selection
- SideScreen USB and wireless launch actions
- Automatic re-sleep and bag-wake protection
- Low-battery and lock-screen voice alerts
- App Intents for AirPlay and SideScreen actions
- URL actions: `headlesstools://airplay`, `headlesstools://sidescreen-usb`, and `headlesstools://sidescreen-wireless`

The app is an `LSUIElement` and does not appear in the Dock. Its menu icon is a template image that adapts to light and dark menu bars.

## Project layout

- `Sources/`: SwiftUI app, system monitoring, power management, App Intents, and the privileged lid helper
- `Tools/`: the only source copies of the scripts and helper tools launched or managed by the app
- `Assets/`: menu-bar artwork
- `script/build_and_run.sh`: build, bundle, sign, launch, and verify entry point

Enabled background tools install their runtime copies under:

```text
~/Library/Application Support/Headless MacBook Tools/Agents
```

Their source remains in this repository's `Tools/` directory.

## Build and run

Requirements: macOS 14+, Apple Silicon, and the Swift toolchain included with the installed Command Line Tools.

```zsh
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

The staged application is written to `dist/HeadlessMacBookTools.app` and ad-hoc signed.

## Shortcuts and keyboard shortcuts

The app exposes `Run Headless Tool` through App Intents. Use the Shortcuts app to select the action and assign a keyboard shortcut from the shortcut's Details panel.

App Intents can provide actions and preconfigured App Shortcuts, but macOS keeps the actual keyboard combination as a user-owned Shortcuts preference. The app does not modify that preference programmatically.

## Permissions

- AirPlay UI automation may require Accessibility and Automation access.
- SideScreen requires Screen & System Audio Recording access; its UI fallback may also require Accessibility.
- The experimental lid-close override installs a narrowly scoped privileged helper after administrator approval.

The normal Clamshell Ready path uses a temporary IOKit power assertion. The lid-close override is not a supported public Apple API and changes a system-wide battery sleep setting.
