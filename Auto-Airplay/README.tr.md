# Auto-Airplay

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

Auto-Airplay, macOS'ta AirPlay / Screen Mirroring alicilarini bulup klavyeden tek tusla secmeyi kolaylastiran kucuk bir otomasyon paketidir.

Ana kullanim senaryosu: Mac'i headless veya hizli-kisayol odakli kullanirken ekrani bir AirPlay alicisina yansitmak. Uygulama acilinca kisa bir bip sesi verir, uygun AirPlay cihazlarini tarar, cihaz isimlerini sesli okur ve secim icin Terminal'de sayi bekler.

## Ne ise yarar?

- macOS Screen Mirroring arayuzundeki AirPlay alicilarini listeler.
- Cihaz listesini `~/.airplay_devices` dosyasina yazar.
- Cihazlari sesli okur.
- Terminal'den `1`, `2`, `3` gibi tek tusla secim alir.
- Secilen cihaza AppleScript / System Events uzerinden baglanmayi dener.
- Hata durumunda sesli ve log tabanli geri bildirim verir.

## Klasor yapisi

```text
Auto-Airplay/
  Auto-Airplay.app              macOS launcher app
  StartAirPlay.swift            launcher kaynak kodu
  run-airplay.sh                app tarafindan calistirilan ana wrapper
  Airplay.sh                    cihaz kesfi + secim akisinin giris noktasi
  ListAirplayDevices.sh         Screen Mirroring cihazlarini bulur
  PickAirplayDevice.sh          Terminal'de tek tus secimi alir
  ConnectAirplay.sh             secilen cihaza baglanir
  CloseAirplayTerminal.sh       yardimci terminal kapatma scripti
  login-beep.sh                 login/session sesli kontrol yardimcisi
  com.eky.login-beep.plist      launchd plist ornegi
  test-headless-airplay.command hizli manuel test komutu
```

## Nasil calisir?

1. `Auto-Airplay.app` acilir.
2. Bundle icindeki `StartAirPlay` binary'si `/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh` dosyasini calistirir.
3. `run-airplay.sh` kendi bulundugu klasoru script klasoru kabul eder.
4. `Airplay.sh`, `ListAirplayDevices.sh --list-only` ile AirPlay cihazlarini tarar.
5. Bulunan cihazlar `~/.airplay_devices` icine `id|ad` formatinda yazilir.
6. Cihaz isimleri macOS `say` komutuyla okunur.
7. Terminal aciksa secim ayni terminalden alinir; degilse gecici bir `.command` dosyasi ile Terminal acilir.
8. `PickAirplayDevice.sh` secimi alir ve `ConnectAirplay.sh <numara>` calistirir.
9. `ConnectAirplay.sh`, System Settings / Control Center Screen Mirroring UI'sini AppleScript ile kullanarak hedef cihaza baglanir.

## Gereksinimler

- macOS.
- AirPlay / Screen Mirroring destekleyen bir hedef cihaz.
- macOS Accessibility ve Automation izinleri.
- `say`, `afplay`, `osascript`, `open`, `bash` gibi macOS sistem araclari.

## Izinler

Bu otomasyon UI kontrol ettigi icin izinler onemli:

- `System Settings > Privacy & Security > Accessibility`
  - Terminal veya app'i calistiran uygulama icin izin ver.
  - `Auto-Airplay.app` dogrudan calistirilacaksa ona da izin gerekebilir.
- `System Settings > Privacy & Security > Automation`
  - System Events / System Settings kontrolu icin izin isteyebilir.

Izinler eksikse cihaz bulunabilir ama tiklama/baglanma adimi calismayabilir.

## Calistirma

App olarak:

```bash
open "/Users/eky/Documents/MacOS Apps/Auto-Airplay/Auto-Airplay.app"
```

Script olarak:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh"
```

Preflight kontrolu:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh" --preflight
```

Sadece bip testi:

```bash
"/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh" --beep-only
```

## Ortam degiskenleri

`run-airplay.sh` su override'lari destekler:

```bash
AIRPLAY_REPO_DIR="/path/to/scripts"
AIRPLAY_ENTRYPOINT="Airplay.sh"
AIRPLAY_BEEP_SOUND="/System/Library/Sounds/Funk.aiff"
AIRPLAY_BEEP_DURATION_SECONDS="0.07"
```

Normal kullanimda bunlara gerek yoktur; scriptler ayni klasorde durdugu icin otomatik bulunur.

## Loglar

Launcher loglari:

```text
~/Library/Logs/StartAirPlay/start-airplay.log
```

Hata ayiklamak icin once bu dosyaya bak.

## Launchd login beep

`com.eky.login-beep.plist`, login/session durumunda `login-beep.sh` calistirmak icin ornek launchd plist'idir.

Plist icindeki script yolu:

```text
/Users/eky/Documents/MacOS Apps/Auto-Airplay/login-beep.sh
```

Bu ozellik AirPlay baglantisi icin zorunlu degildir; sadece yardimci geri bildirimdir.

## GitHub'a koyarken

Bu paket su an kisisel path ile derlenmis bir launcher icerir:

```text
/Users/eky/Documents/MacOS Apps/Auto-Airplay/run-airplay.sh
```

Acik kaynak yapmak icin daha tasinabilir hale getirmek iyi olur:

- `StartAirPlay.swift` icindeki mutlak path yerine app bundle yanindaki scripti bulacak yapi kur.
- `com.eky.login-beep.plist` icindeki kullanici path'ini ornek/template olarak ayir.
- README'deki kisisel path'leri kurulum adimina tasimayi dusun.

## Sorun giderme

`Required file not found`:

- Scriptlerin ayni klasorde oldugunu kontrol et.
- `run-airplay.sh --preflight` calistir.

Cihazlar bulunmuyor:

- AirPlay hedefinin ayni agda ve acik oldugunu kontrol et.
- macOS Screen Mirroring menusunde cihaz gorunuyor mu bak.

Secim yapiliyor ama baglanmiyor:

- Accessibility / Automation izinlerini kontrol et.
- macOS arayuz metinleri degistiyse `ListAirplayDevices.sh` ve `ConnectAirplay.sh` icindeki AppleScript secicileri guncellenebilir.

Terminal aciliyor ama sesli okuma takiliyor:

- `pkill -x say` ile eski `say` surecleri temizlenebilir.

## Lisans

Bu proje reponun [MIT Lisansi](../LICENSE) kapsamindadir.
