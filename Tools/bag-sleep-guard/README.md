# Bag Sleep Guard

A LaunchAgent managed by Headless MacBook Tools. If the Mac wakes while locked and running on battery, it returns the Mac to sleep when no recent keyboard or trackpad input is detected.

It does not run after the user has unlocked the session.

Runtime files are installed under:

```text
~/Library/Application Support/Headless MacBook Tools/Agents/bag-sleep-guard
```

Temporary opt-out:

```zsh
touch ~/.bag-sleep-guard-off
```

Remove the marker to enable the guard again. Normal installation and removal should be performed with the Bag Sleep Guard switch in Headless MacBook Tools.
