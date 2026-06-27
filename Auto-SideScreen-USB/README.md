# Auto-SideScreen-USB

[English](README.md) | [Türkçe](README.tr.md)

[Main repository: Headless MacBook Tools](../README.md)

Auto-SideScreen-USB is a small launcher and shortcut package for starting the SideScreen macOS app quickly in USB mode.

Its primary use case is connecting an Android tablet or phone over USB as a second display and starting SideScreen's USB mode with one shortcut.

## Features

- Plays a short beep when `Auto-SideScreen-USB.app` opens.
- First attempts to open the `sidescreen://auto-start-usb` URL scheme.
- Lets SideScreen handle its own USB auto-start flow when the URL scheme succeeds.
- Falls back to opening `/Applications/SideScreen.app` with `--auto-start-usb`.
- Includes optional UI automation scripts for selecting USB or wireless mode and pressing `Start`.

## Directory Layout

```text
Auto-SideScreen-USB/
  Auto-SideScreen-USB.app                macOS launcher app
  StartSideScreenUSB.swift               launcher source
  SideScreen.sh                          UI automation script
  SideScreen-usb.sh                      USB wrapper
  SideScreen-wireless.sh                 wireless wrapper
  sidescreen-aerospace-snippet.toml      AeroSpace shortcut example
  sidescreen-karabiner-simultaneous.json Karabiner shortcut example
  README.md                              English documentation
  README.tr.md                           Turkish documentation
```

## How It Works

### App Flow

1. `Auto-SideScreen-USB.app` launches.
2. Its `StartSideScreenUSB` binary runs.
3. It writes to `~/Library/Logs/StartSideScreen/start-sidescreen-usb.log`.
4. It plays a short `/System/Library/Sounds/Funk.aiff` beep.
5. It opens `sidescreen://auto-start-usb`.
6. If the URL scheme fails, it tries `/Applications/SideScreen.app --auto-start-usb`.
7. If the fallback also fails, it logs the error and plays an error sound.

### Script Flow

`SideScreen-usb.sh` delegates to the shared script:

```bash
script_dir=$(cd "$(dirname "$0")" && pwd)
exec "$script_dir/SideScreen.sh" usb
```

`SideScreen.sh usb` then:

1. Opens `/Applications/SideScreen.app`.
2. Waits for the `Side Screen` process through AppleScript.
3. Finds a tab named `USB`, `Wired`, or `Cable`.
4. Selects the tab.
5. Finds and presses the `Start` button.

Wireless mode uses the same script and looks for `Wireless`, `Wi-Fi`, or `WiFi`.

## Requirements

- macOS.
- The SideScreen app.
- An Android device and the required USB permissions for wired use.
- Screen Recording permission for SideScreen on macOS.
- Accessibility and Automation permissions when using the UI scripts.

The expected application path is:

```text
/Applications/SideScreen.app
```

A source checkout may live at the following location, but the launcher fallback still expects the app under `/Applications`:

```text
/Users/eky/Documents/MacOS Apps/SideScreen
```

## Permissions

For SideScreen:

- Allow SideScreen under `System Settings > Privacy & Security > Screen & System Audio Recording`.

For the UI automation scripts:

- Allow Terminal, AeroSpace, Karabiner, or the invoking app under `Accessibility`.
- Allow System Events control under `Automation` when prompted.

The URL-scheme launcher normally does not need click automation. `SideScreen.sh` does, so it depends on Accessibility permission.

## Run

As an app:

```bash
open "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/Auto-SideScreen-USB.app"
```

USB script:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-usb.sh"
```

Wireless script:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-wireless.sh"
```

Select a mode directly:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen.sh" usb
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen.sh" wireless
```

## Shortcut Examples

### macOS Shortcuts

1. Create a shortcut in the Shortcuts app.
2. Add an `Open App` action.
3. Select `Auto-SideScreen-USB.app`.
4. Assign a keyboard shortcut.

### AeroSpace

The included `sidescreen-aerospace-snippet.toml` contains:

```toml
ctrl-alt-s = '''exec-and-forget /bin/bash -lc "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-usb.sh"'''
ctrl-alt-w = '''exec-and-forget /bin/bash -lc "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-wireless.sh"'''
```

### Karabiner

`sidescreen-karabiner-simultaneous.json` contains shell-command examples for the USB and wireless scripts.

## Logs

Launcher logs are written to:

```text
~/Library/Logs/StartSideScreen/start-sidescreen-usb.log
```

The file records launch attempts, URL-scheme success, and fallback failures.

## Portability Notes

The package currently favors the local setup. For a portable installation:

- Move `/Users/eky/Documents/MacOS Apps/...` paths into installation documentation or templates.
- Make the `/Applications/SideScreen.app` fallback configurable in `StartSideScreenUSB.swift`.
- Match URL-scheme behavior to the installed upstream SideScreen version.
- Document reproducible bundle build steps.

## Troubleshooting

The app opens but SideScreen does not start:

- Confirm that `/Applications/SideScreen.app` exists.
- Open SideScreen manually once and complete its permission prompts.
- Check `~/Library/Logs/StartSideScreen/start-sidescreen-usb.log`.

USB mode does not start:

- Confirm that the Android device is connected over USB.
- Complete USB debugging and permission prompts on Android.
- Test USB mode manually in SideScreen.

The script cannot find the `Start` button:

- The SideScreen UI language or button name may have changed.
- Accessibility permission may be missing.
- Update the `USB`, `Wired`, `Cable`, and `Start` names in `SideScreen.sh` if needed.

The URL scheme does not work:

- The installed SideScreen version may not support `sidescreen://auto-start-usb`.
- The launcher will try `/Applications/SideScreen.app --auto-start-usb` as a fallback.

## License

This project is covered by the repository's [MIT License](../LICENSE).
