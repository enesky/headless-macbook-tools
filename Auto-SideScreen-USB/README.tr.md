# Auto-SideScreen-USB

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

Auto-SideScreen-USB, SideScreen macOS uygulamasini USB modunda hizli baslatmak icin hazirlanmis kucuk bir launcher ve kisayol paketidir.

Ana kullanim senaryosu: Android tablet/telefonu USB ile Mac'e ikinci ekran gibi baglamak ve SideScreen'de USB modunu tek kisayolla baslatmak.

## Ne ise yarar?

- `Auto-SideScreen-USB.app` acilinca kisa bir bip sesi verir.
- Once `sidescreen://auto-start-usb` URL scheme'ini acmayi dener.
- URL scheme basariliysa SideScreen kendi USB auto-start akisina girer.
- URL scheme acilamazsa fallback olarak `/Applications/SideScreen.app` uygulamasini `--auto-start-usb` argumaniyla acmayi dener.
- Ek scriptler ile SideScreen UI'sinde USB veya wireless sekmesini secip `Start` butonuna basma otomasyonu da bulunur.

## Klasor yapisi

```text
Auto-SideScreen-USB/
  Auto-SideScreen-USB.app              macOS launcher app
  StartSideScreenUSB.swift             launcher kaynak kodu
  SideScreen.sh                        UI automation scripti
  SideScreen-usb.sh                    SideScreen.sh usb wrapper'i
  SideScreen-wireless.sh               SideScreen.sh wireless wrapper'i
  sidescreen-aerospace-snippet.toml    AeroSpace kisayol ornegi
  sidescreen-karabiner-simultaneous.json Karabiner kisayol ornegi
  README.md                            bu dokuman
```

## Nasil calisir?

### App akisi

1. `Auto-SideScreen-USB.app` acilir.
2. Bundle icindeki `StartSideScreenUSB` binary'si calisir.
3. `~/Library/Logs/StartSideScreen/start-sidescreen-usb.log` icine log yazar.
4. `/System/Library/Sounds/Funk.aiff` ile kisa bip calar.
5. `sidescreen://auto-start-usb` URL scheme'i acilir.
6. URL scheme basarisiz olursa `/Applications/SideScreen.app --auto-start-usb` fallback'i denenir.
7. Fallback de basarisizsa hata loglanir ve hata sesi calar.

### Script akisi

`SideScreen-usb.sh`:

```bash
script_dir=$(cd "$(dirname "$0")" && pwd)
exec "$script_dir/SideScreen.sh" usb
```

`SideScreen.sh usb`:

1. `/Applications/SideScreen.app` uygulamasini acar.
2. AppleScript ile `Side Screen` process'ini bekler.
3. UI icinde `USB`, `Wired` veya `Cable` adli sekmeyi arar.
4. Sekmeyi secer.
5. `Start` butonunu bulup basar.

Wireless icin ayni script `Wireless`, `Wi-Fi`, `WiFi` sekme adlarini arar.

## Gereksinimler

- macOS.
- SideScreen uygulamasi.
- USB kullanim icin Android cihaz ve gerekli USB izinleri.
- SideScreen'in macOS tarafinda gerekli Screen Recording izni.
- UI automation scriptleri kullanilacaksa Accessibility / Automation izinleri.

Varsayilan SideScreen app yolu:

```text
/Applications/SideScreen.app
```

SideScreen repo kopyasi su klasorde durabilir, ama launcher fallback'i `/Applications/SideScreen.app` bekler:

```text
/Users/eky/Documents/MacOS Apps/SideScreen
```

## Izinler

SideScreen icin:

- `System Settings > Privacy & Security > Screen & System Audio Recording`
  - SideScreen'e izin ver.

UI automation scriptleri icin:

- `System Settings > Privacy & Security > Accessibility`
  - Terminal, AeroSpace, Karabiner veya scripti calistiran uygulamaya izin ver.
- `System Settings > Privacy & Security > Automation`
  - System Events kontrolu icin izin gerekebilir.

Not: `Auto-SideScreen-USB.app` URL scheme uzerinden baslatirken genelde UI tiklama otomasyonuna ihtiyac duymaz. `SideScreen.sh` scripti ise UI tiklama yaptigi icin Accessibility iznine baglidir.

## Calistirma

App olarak:

```bash
open "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/Auto-SideScreen-USB.app"
```

USB script olarak:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-usb.sh"
```

Wireless script olarak:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-wireless.sh"
```

Direkt mod secerek:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen.sh" usb
"/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen.sh" wireless
```

## Kisayol ornekleri

### macOS Shortcuts

1. Shortcuts uygulamasinda yeni shortcut olustur.
2. `Open App` aksiyonu ekle.
3. App olarak `Auto-SideScreen-USB.app` sec.
4. Klavye kisayolu ata.

### AeroSpace

`sidescreen-aerospace-snippet.toml` icindeki ornek:

```toml
ctrl-alt-s = '''exec-and-forget /bin/bash -lc "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-usb.sh"'''
ctrl-alt-w = '''exec-and-forget /bin/bash -lc "/Users/eky/Documents/MacOS Apps/Auto-SideScreen-USB/SideScreen-wireless.sh"'''
```

### Karabiner

`sidescreen-karabiner-simultaneous.json`, USB ve wireless scriptleri icin shell command ornegi icerir.

## Loglar

Launcher loglari:

```text
~/Library/Logs/StartSideScreen/start-sidescreen-usb.log
```

Burada launch denemeleri, URL scheme basarisi ve fallback hatalari gorulur.

## GitHub'a koyarken

Bu paket su an kisisel kullanim icin pratik tutuldu. Acik kaynak yapmak icin su noktalar temizlenebilir:

- `/Users/eky/Documents/MacOS Apps/...` path'lerini kurulum dokumanina veya template dosyalarina tasima.
- `StartSideScreenUSB.swift` icindeki `/Applications/SideScreen.app` fallback yolunu ayarlanabilir yapma.
- SideScreen'in URL scheme davranisini README'de upstream SideScreen surumuyle eslestirme.
- Bundle build adimlarini ekleme.

## Sorun giderme

App aciliyor ama SideScreen baslamiyor:

- `/Applications/SideScreen.app` var mi kontrol et.
- SideScreen'i bir kez elle acip izinlerini tamamla.
- `~/Library/Logs/StartSideScreen/start-sidescreen-usb.log` dosyasina bak.

USB modu baslamiyor:

- Android cihaz USB ile bagli mi kontrol et.
- Android tarafinda USB debugging / izin prompt'lari tamam mi kontrol et.
- SideScreen icindeki USB modu elle basliyor mu test et.

Script `Start` butonunu bulamiyor:

- SideScreen UI dili veya buton adi degismis olabilir.
- Accessibility izni eksik olabilir.
- `SideScreen.sh` icindeki `USB`, `Wired`, `Cable`, `Start` adlari guncellenebilir.

URL scheme calismiyor:

- SideScreen'in kurulu surumu `sidescreen://auto-start-usb` scheme'ini desteklemiyor olabilir.
- Bu durumda fallback `/Applications/SideScreen.app --auto-start-usb` denenir.

## Lisans

Bu proje reponun [MIT Lisansi](../LICENSE) kapsamindadir.
