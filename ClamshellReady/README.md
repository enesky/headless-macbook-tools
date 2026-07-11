# Clamshell Ready

Native SwiftUI menu bar app for Apple Silicon Macs. It helps keep a MacBook awake for external-display workflows without changing global sleep behavior unless the user explicitly enables lid-close override mode.

## Behavior

- If no real external display is connected, the app does not try to keep the system awake.
- Virtual displays or displays without valid hardware vendor/model IDs do not activate the sleep-prevention assertion.
- When **Clamshell Ready** is enabled and conditions are met, the app creates a temporary IOKit `PreventSystemSleep` assertion.
- When **Clamshell Ready** is disabled or **Quit** is clicked, the app releases its assertion and restores lid behavior with `SleepDisabled=0` if lid override is active.
- **Allow on Battery** lets the assertion activate with an external display even without a power adapter.
- **Ignore Lid Close (Disable sleep)** uses the Fermata-style `pmset -b disablesleep 1/0` workaround through the local privileged LaunchDaemon helper.
- **Go to Sleep** releases the app's temporary assertion, temporarily disables **Ignore Lid Close (Disable sleep)** if needed, asks IOKit to put the Mac to sleep, and restores the user's lid-override preference after wake.
- Lid state is shown when macOS exposes it through IORegistry.
- **Dim Built-in Display** is shown only when a built-in display is detected. It immediately sets only that display's brightness to zero when enabled and after wake. If **Launch at Login** is also enabled, it applies as soon as the app starts on later logins. External displays are not changed.
- The app clears its assertion when it exits normally.

The standard mode uses supported IOKit power assertions. **Ignore Lid Close (Disable sleep)** is not a supported public Apple API; it changes the system-wide battery `disablesleep` setting. Normal app shutdown attempts to restore that setting, but a force quit, crash, or power loss can leave it enabled.

## Privileged lid helper

The first **Ignore Lid Close (Disable sleep)** action installs the helper from inside the app bundle and shows the normal macOS administrator dialog once. After that, normal app use does not need repeated prompts.

You can also install it manually:

```zsh
chmod +x script/install_lid_daemon.sh script/uninstall_lid_daemon.sh
./script/install_lid_daemon.sh
```

The installer asks for administrator approval once because it installs a root LaunchDaemon at:

- `/Library/LaunchDaemons/com.eky.ClamshellReady.LidDaemon.plist`
- `/usr/local/libexec/clamshell-ready-lid-daemon`

The daemon accepts local socket requests only from the installing user's UID and only supports two commands: enable or disable battery `disablesleep`.

To remove it and restore normal battery sleep behavior:

```zsh
./script/uninstall_lid_daemon.sh
```

## Build and run

Requirements: macOS 14+, Apple Silicon, and a Swift 6 toolchain.

```zsh
chmod +x script/build_and_run.sh
./script/build_and_run.sh
```

The script builds and stages `dist/ClamshellReady.app`, ad-hoc signs it, and launches it as a menu-bar-only app.

Useful options:

```zsh
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
```

## Launch at Login

Enable **Launch at Login** from the app. macOS may also show the item under System Settings > General > Login Items. Use the staged `.app` bundle rather than launching the raw SwiftPM binary.

## Notes

There is no stable high-level public API for lid state, so some machines may show `Unavailable`. Any assertion or login-item failure is shown in the popover.

Built-in brightness control uses macOS's private `DisplayServices` framework because Apple does not provide a public command-line or high-level API for it. A future macOS update may change this behavior.
