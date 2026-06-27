# Headless Auto Re-Sleep

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

MacBook Air M2 headless kullanimda uyandiktan 3 saniye sonra kontrol eder:

- Harici ekran varsa `waking up` der ve bir sey yapmaz.
- Ekran kilidi gecildiyse sessiz kalir ve bir sey yapmaz.
- Ekran kilidi duruyorken ilk 3 saniye icinde klavye/trackpad aksiyonu algilanmissa `waking up` der.
- Harici ekran yoksa ve aksiyon yoksa `auto re-sleep` der, sonra `pmset sleepnow` calistirir.
- Aksiyon surekli basili kalan tus gibi gorunurse konusmaz; kisa ses cikarir, sonra `pmset sleepnow` calistirir.

## Kurulum

```zsh
cd "/Users/eky/Documents/Codex/2026-06-25/tu/outputs/headless-auto-resleep"
chmod +x install.sh uninstall.sh
./install.sh
```

## Kaldirma

```zsh
cd "/Users/eky/Documents/Codex/2026-06-25/tu/outputs/headless-auto-resleep"
./uninstall.sh
```

## Log

```zsh
tail -f ~/Library/Logs/headless-auto-resleep.log
```
