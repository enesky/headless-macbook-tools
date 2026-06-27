# Bag Sleep Guard

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

MacBook cantada yanlislikla uyanirsa, kilit ekraninda input gelmezse geri uyutur.

Kur:

```zsh
chmod +x install.sh uninstall.sh
./install.sh
```

Gecici kapat:

```zsh
touch ~/.bag-sleep-guard-off
```

Tekrar ac:

```zsh
rm ~/.bag-sleep-guard-off
```

Kaldir:

```zsh
./uninstall.sh
```

Mantik: bataryadaysa, ekran kilitliyse ve 5 saniyedir klavye/trackpad input yoksa `pmset sleepnow`.

Giris yaptiktan sonra calismaz; sadece kilit ekraninda uyutur.

Bekleme suresini degistirmek icin `bag-sleep-guard.sh` icindeki `INPUT_WAIT_SECONDS` degerini degistir.
