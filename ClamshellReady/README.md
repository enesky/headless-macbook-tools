# Clamshell Ready

Native SwiftUI menu bar app for Apple Silicon Macs. It helps keep a MacBook awake for external-display workflows without changing global sleep behavior unless the user explicitly enables lid-close override mode.

## Behavior

- If no real external display is connected, the app does not try to keep the system awake.
- Virtual displays or displays without valid hardware vendor/model IDs do not activate the sleep-prevention assertion.
- When **Clamshell Ready** is enabled and conditions are met, the app creates a temporary IOKit `PreventSystemSleep` assertion.
- When **Clamshell Ready** is disabled or **Quit** is clicked, the app releases its assertion and restores lid behavior with `SleepDisabled=0` if lid override is active.
- **Allow on Battery** lets the assertion activate with an external display even without a power adapter.
- **Ignore Lid Close (Disable sleep)** uses the Fermata-style `pmset -b disablesleep 1/0` workaround and requires administrator approval.
- **Go to Sleep** releases the app's temporary assertion and then asks IOKit to put the Mac to sleep. It does not change **Ignore Lid Close (Disable sleep)**.
- Lid state is shown when macOS exposes it through IORegistry.
- The app clears its assertion when it exits normally.

The standard mode uses supported IOKit power assertions. **Ignore Lid Close (Disable sleep)** is not a supported public Apple API; it changes the system-wide battery `disablesleep` setting. Normal app shutdown attempts to restore that setting, but a force quit, crash, or power loss can leave it enabled.

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
