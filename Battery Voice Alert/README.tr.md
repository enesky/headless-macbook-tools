# Battery Voice Alert

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

MacBook bataryasi duserken sesli uyari verir. App degil; macOS `LaunchAgent`
olarak bes dakikada bir calisan kucuk bir script.

## Kurulum

```zsh
/Users/eky/Documents/Codex/MacOS\ Apps/Battery\ Voice\ Alert/BatteryVoiceAlert.command install
```

## Kaldirma

```zsh
~/.local/bin/battery-voice-alert uninstall
```

## Test

```zsh
~/.local/bin/battery-voice-alert check
/Users/eky/Documents/Codex/MacOS\ Apps/Battery\ Voice\ Alert/BatteryVoiceAlert.command self-test
```

## Esikler

- `%25` ve ustunde susar.
- `%25` altinda: `%24`, `%20`, `%15`, `%10`.
- `%10` altinda: `%9`, `%8`, `%6`, `%4`, `%2`, `%1`.
- Sarja takiliyken son uyari sifirlanir.
