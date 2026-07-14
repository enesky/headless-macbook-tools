# Auto-Airplay

The AirPlay action used by Halftop.

It discovers receivers from the macOS Screen Mirroring interface, writes the list to `~/.airplay_devices`, reads receiver names aloud, and accepts a numeric selection in Terminal. The selected receiver is activated through System Events UI automation.

## Requirements

- An available AirPlay or Screen Mirroring receiver
- Accessibility and Automation access for Halftop or the Terminal process it opens
- macOS system tools including `osascript`, `say`, and `afplay`

## Entry point

Halftop runs:

```zsh
./run-airplay.sh
```

Useful diagnostics:

```zsh
./run-airplay.sh --preflight
./run-airplay.sh --beep-only
```

This directory is bundled under `Contents/Resources/Tools/Auto-Airplay`. It is not a standalone app and should not be duplicated beside Halftop.
