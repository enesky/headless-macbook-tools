# Headless Auto Re-Sleep

[English](README.md) | [Türkçe](README.tr.md)

[Main repository: Headless MacBook Tools](../README.md)

Checks the state of a headless MacBook Air M2 three seconds after it wakes:

- If an external display is connected, it says `waking up` and does nothing.
- If the lock screen has already been dismissed, it remains silent and does nothing.
- If keyboard or trackpad activity is detected during the first three seconds while the lock screen is active, it says `waking up`.
- If there is no external display and no activity, it says `auto re-sleep`, then runs `pmset sleepnow`.
- If the activity resembles a continuously held key, it plays a short sound instead of speaking, then runs `pmset sleepnow`.

## Install

```zsh
cd "/Users/eky/Documents/Codex/2026-06-25/tu/outputs/headless-auto-resleep"
chmod +x install.sh uninstall.sh
./install.sh
```

## Uninstall

```zsh
cd "/Users/eky/Documents/Codex/2026-06-25/tu/outputs/headless-auto-resleep"
./uninstall.sh
```

## Logs

```zsh
tail -f ~/Library/Logs/headless-auto-resleep.log
```
