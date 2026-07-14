# SideScreen Launch Tools

USB and wireless SideScreen launch actions used by Halftop.

The preferred path opens SideScreen through its URL scheme. The fallback opens `/Applications/SideScreen.app` and uses UI automation to select USB or wireless mode and press Start.

## Requirements

- SideScreen installed at `/Applications/SideScreen.app`
- Screen & System Audio Recording permission for SideScreen
- Accessibility and Automation permission when the UI fallback is used

## Entry points

```zsh
./SideScreen-usb.sh
./SideScreen-wireless.sh
```

Halftop invokes these scripts directly from its application bundle. App Intents are the preferred shortcut integration.
