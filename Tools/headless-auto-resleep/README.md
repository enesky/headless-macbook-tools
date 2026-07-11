# Headless Auto Re-Sleep

A LaunchAgent managed by Headless MacBook Tools. After wake it checks for a physical external display, an unlocked session, and recent keyboard or trackpad input. If none is present, it announces auto re-sleep and asks macOS to sleep again.

Runtime files are installed under:

```text
~/Library/Application Support/Headless MacBook Tools/Agents/headless-auto-resleep
```

Log:

```zsh
tail -f ~/Library/Logs/headless-auto-resleep.log
```

Normal installation and removal should be performed with the Automatic Re-Sleep switch in Headless MacBook Tools.
