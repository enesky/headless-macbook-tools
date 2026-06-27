# Headless MacBook Tools

[English](README.md) | [Türkçe](README.tr.md)

Headless veya kisayol odakli MacBook kullaniminda ihtiyac duydugumuz macOS app, LaunchAgent ve otomasyon scriptleri.

Bu repo, `MacOS Apps` klasorunde gelistirilen araclari tek yerde toplar. Amac; kurulabilir scriptleri, kucuk Swift launcher uygulamalarini, launchd plist dosyalarini ve SideScreen yardimci otomasyonlarini kaybolmadan saklamak.

## Araclar

| Arac | Tip | Ne ise yarar? |
| --- | --- | --- |
| [Auto-Airplay](Auto-Airplay/README.tr.md) | Swift launcher + shell scriptleri | AirPlay / Screen Mirroring alicilarini bulur, sesli okur ve klavyeden secimle baglanmayi dener. |
| [Auto-SideScreen-USB](Auto-SideScreen-USB/README.tr.md) | Swift launcher + UI automation | SideScreen'i USB modunda tek kisayolla baslatir. |
| [Battery Voice Alert](Battery%20Voice%20Alert/README.tr.md) | LaunchAgent scripti | MacBook bataryasi belirli esiklerin altina dusunce sesli uyari verir. |
| [Bag Sleep Guard](bag-sleep-guard/README.tr.md) | LaunchAgent scripti | Cantada/kapaliyken yanlislikla uyanan MacBook'u input yoksa tekrar uyutur. |
| [Headless Auto Re-Sleep](headless-auto-resleep/README.tr.md) | Swift helper + installer | Headless uyanmalarda ekran/input kontrolu yapip gerekirse otomatik tekrar uyutur. |
| [Lock Screen Sayer](lock-screen-sayer/README.tr.md) | Swift helper + LaunchAgent | Ekran kilitlenince sesli bildirim verir. |
| [SideScreen](SideScreen/README.tr.md) | macOS + Android app | Android tablet/telefonu macOS icin ikinci ekran olarak kullanmaya yarayan app ve yardimci kaynaklar. |

## Repo kapsami

Bu repoda kaynak kodlar, scriptler, plist ornekleri, README dosyalari ve gerekli proje dosyalari tutulur.

Yerel build/cache/veri kalintilari repoya alinmaz:

- `.git/`
- `.build/`
- `.clang-module-cache/`
- `.DS_Store`

## Genel notlar

- Bu araclar macOS odaklidir.
- UI otomasyonu kullanan araclar icin `Privacy & Security > Accessibility` ve `Automation` izinleri gerekebilir.
- Uyku, ekran kilidi, AirPlay ve SideScreen akislari cihaza ve macOS surumune bagli olarak izin veya arayuz farklarindan etkilenebilir.
- Kurulum/kaldirma adimlari her aracin kendi README dosyasindadir.

## GitHub

[enesky/headless-macbook-tools](https://github.com/enesky/headless-macbook-tools)
