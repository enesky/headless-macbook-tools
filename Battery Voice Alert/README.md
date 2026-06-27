# Battery Voice Alert

[English](README.md) | [Türkçe](README.tr.md)

[Main repository: Headless MacBook Tools](../README.md)

Announces battery warnings while the MacBook is discharging. This is not an app; it is a small script run once every five minutes by a macOS `LaunchAgent`.

## Install

```zsh
/Users/eky/Documents/Codex/MacOS\ Apps/Battery\ Voice\ Alert/BatteryVoiceAlert.command install
```

## Uninstall

```zsh
~/.local/bin/battery-voice-alert uninstall
```

## Test

```zsh
~/.local/bin/battery-voice-alert check
/Users/eky/Documents/Codex/MacOS\ Apps/Battery\ Voice\ Alert/BatteryVoiceAlert.command self-test
```

## Thresholds

- Silent at 25% and above.
- Below 25%: announces 24%, 20%, 15%, and 10%.
- Below 10%: announces 9%, 8%, 6%, 4%, 2%, and 1%.
- Connecting the charger resets the most recent warning.
