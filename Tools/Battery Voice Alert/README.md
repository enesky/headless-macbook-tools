# Battery Voice Alert

A LaunchAgent managed by Halftop. It checks battery state once per minute and speaks selected low-charge warnings while the Mac is discharging.

Warning levels are 24, 20, 15, 10, 9, 8, 6, 4, 2, and 1 percent. Connecting power resets the last warning.

Runtime files are installed under:

```text
~/Library/Application Support/Halftop/Agents/battery-voice-alert
```

Manual diagnostics:

```zsh
./Halftop self-test
./Halftop check
```

Normal installation and removal should be performed with the Low Battery Voice Alert switch in Halftop.
