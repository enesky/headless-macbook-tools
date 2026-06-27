# Auto-Airplay

[English](README.md) | [Türkçe](README.tr.md)

[Main repository: Headless MacBook Tools](../README.md)

Auto-Airplay is a small macOS automation package for discovering AirPlay / Screen Mirroring receivers and selecting one with a single key.

It is designed for headless or shortcut-driven Mac use. When launched, it plays a short beep, scans for available AirPlay devices, reads their names aloud, and waits for a numeric selection in Terminal.

## Features

- Lists receivers exposed by the macOS Screen Mirroring interface.
- Writes the device list to `~/.airplay_devices`.
- Reads device names aloud.
- Accepts a single-key selection such as `1`, `2`, or `3` in Terminal.
- Attempts to connect through AppleScript and System Events.
- Provides spoken and file-based error feedback.

## Directory Layout

```text
Auto-Airplay/
  Auto-Airplay.app              macOS launcher app
  StartAirPlay.swift            launcher source
  run-airplay.sh                main wrapper called by the app
  Airplay.sh                    discovery and selection entry point
  ListAirplayDevices.sh         discovers Screen Mirroring devices
  PickAirplayDevice.sh          reads a single-key Terminal selection
  ConnectAirplay.sh             connects to the selected device
  CloseAirplayTerminal.sh       Terminal cleanup helper
  login-beep.sh                 login/session audio helper
  com.eky.login-beep.plist      sample launchd property list
  test-headless-airplay.command quick manual test command
```

## How It Works

1. `Auto-Airplay.app` launches.
2. Its `StartAirPlay` binary runs `/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh`.
3. `run-airplay.sh` treats its own directory as the scripts directory.
4. `Airplay.sh` scans with `ListAirplayDevices.sh --list-only`.
5. Devices are written to `~/.airplay_devices` in `id|name` format.
6. macOS `say` announces each device name.
7. An existing Terminal is reused when possible; otherwise a temporary `.command` file opens Terminal.
8. `PickAirplayDevice.sh` reads the selection and invokes `ConnectAirplay.sh <number>`.
9. `ConnectAirplay.sh` controls the System Settings or Control Center Screen Mirroring UI through AppleScript.

## Requirements

- macOS.
- An AirPlay / Screen Mirroring receiver.
- Accessibility and Automation permissions.
- Standard macOS tools including `say`, `afplay`, `osascript`, `open`, and `bash`.

## Permissions

Because this package controls system UI, permissions are important:

- Under `System Settings > Privacy & Security > Accessibility`, allow Terminal or the app that runs the scripts. `Auto-Airplay.app` may also need direct permission.
- Under `System Settings > Privacy & Security > Automation`, allow access to System Events and System Settings when prompted.

Discovery may succeed while the click or connection step fails if these permissions are missing.

## Run

As an app:

```bash
open "/Users/eky/Documents/MacOS Apps/Auto-Airplay/Auto-Airplay.app"
```

As a script:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh"
```

Preflight check:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh" --preflight
```

Beep test only:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh" --beep-only
```

## Environment Variables

`run-airplay.sh` supports these overrides:

```bash
AIRPLAY_REPO_DIR="/path/to/scripts"
AIRPLAY_ENTRYPOINT="Airplay.sh"
AIRPLAY_BEEP_SOUND="/System/Library/Sounds/Funk.aiff"
AIRPLAY_BEEP_DURATION_SECONDS="0.07"
```

They are not required for normal use because scripts are discovered relative to the wrapper.

## Logs

Launcher logs are written to:

```text
~/Library/Logs/StartAirPlay/start-airplay.log
```

## Login Beep LaunchAgent

`com.eky.login-beep.plist` is a sample launchd property list for running `login-beep.sh` during login or session events. Its configured script path is:

```text
/Users/eky/Documents/MacOS Apps/Auto-Airplay/login-beep.sh
```

This helper is optional and is not required for AirPlay connections.

## Portability Notes

The bundled launcher currently contains this personal absolute path:

```text
/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh
```

For a portable installation:

- Update `StartAirPlay.swift` to locate the script relative to the app bundle.
- Treat the user path in `com.eky.login-beep.plist` as a template value.
- Replace personal paths in installation examples.

## Troubleshooting

`Required file not found`:

- Confirm that all scripts are in the same directory.
- Run `run-airplay.sh --preflight`.

No devices are found:

- Confirm that the AirPlay receiver is online and on the same network.
- Check whether it appears in the macOS Screen Mirroring menu.

A device is selected but does not connect:

- Check Accessibility and Automation permissions.
- macOS UI changes may require selector updates in `ListAirplayDevices.sh` and `ConnectAirplay.sh`.

Terminal opens but speech gets stuck:

- Run `pkill -x say` to stop stale `say` processes.

## License

This project is covered by the repository's [MIT License](../LICENSE).
