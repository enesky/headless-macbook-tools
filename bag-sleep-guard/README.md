# Bag Sleep Guard

[English](README.md) | [Türkçe](README.tr.md)

[Main repository: Headless MacBook Tools](../README.md)

Returns a MacBook to sleep when it wakes accidentally in a bag and receives no input at the lock screen.

## Install

```zsh
chmod +x install.sh uninstall.sh
./install.sh
```

## Temporarily Disable

```zsh
touch ~/.bag-sleep-guard-off
```

Enable it again:

```zsh
rm ~/.bag-sleep-guard-off
```

## Uninstall

```zsh
./uninstall.sh
```

## Behavior

When running on battery, the screen is locked, and no keyboard or trackpad input has arrived for five seconds, the guard runs `pmset sleepnow`.

It stops acting after login and only returns the Mac to sleep while the lock screen is active.
