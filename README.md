# Halftop

A native SwiftUI menu bar app with macOS utilities and automation tools for halftop and headless MacBook setups.

## Preview

<p align="center">
  <img src="Assets/screenshot.png" alt="Halftop menu" width="354">
</p>

## Features

- **At-a-glance status:** built-in and external displays, AirPlay, lid, power source, and Energy Mode in one 2×3 overview.
- **Clamshell controls:** checks the connected display and power adapter, supports optional battery operation, and includes an experimental lid-close override.
- **Display and power:** dims or disables the built-in display and controls Automatic, Low Power, and supported High Power modes separately for battery and adapter use.
- **AirPlay and [SideScreen](SideScreen/):** selects an AirPlay display or launches [SideScreen](SideScreen/) directly in USB or Wi-Fi mode—no connection-mode selection required.
- **Sleep and alerts:** provides automatic re-sleep, bag-wake protection, low-battery and lock-screen voice alerts, and login, wake, and unlock sounds.
- **Global shortcuts:** customizable from the app's **SHORTCUTS** section.
  - `⌃⌥A` — Start Auto Airplay: Discovers available AirPlay displays, reads them aloud, and connects to the one selected with a number key.
  - `⌃⌥S` — SideScreen USB: Opens [SideScreen](SideScreen/), auto-selects USB mode and starts the connection automatically.
  - `⌃⌥W` — SideScreen Wireless: Opens [SideScreen](SideScreen/), auto-selects Wi-Fi mode and starts the connection automatically.
  - `⌃⌥⌘S` — Sleep Now: Puts the Mac to sleep, even while Halftop’s sleep prevention is enabled.

## Install

Requires macOS 14 or later on Apple Silicon.

1. Download the latest `Halftop-v*.zip` from [GitHub Releases](https://github.com/enesky/halftop/releases/latest).
2. Unzip it and move `Halftop.app` to **Applications**.
3. Open Halftop. It runs from the menu bar and does not appear in the Dock.

## Build from source

For development, install Xcode Command Line Tools and run:

```zsh
./script/build_and_run.sh
```

This builds, bundles, signs, and opens `dist/Halftop.app`.
Use `./script/build_and_run.sh --verify` to also confirm that the app launched successfully.
