<a id="readme-top"></a>

[English](README.md) | [Türkçe](README.tr.md)

[Ana repo: Headless MacBook Tools](../README.tr.md)

<div align="center">

<img src="resources/logo/sidescreen-icon.png" alt="Side Screen" width="128"/>

<h1>Side Screen</h1>

<p><em>Android tabletinizi USB-C veya Wi-Fi üzerinden macOS için ikinci ekrana dönüştürün</em></p>

![Swift](https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)
![macOS](https://img.shields.io/badge/macOS_13+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android_8+-3DDC84?style=for-the-badge&logo=android&logoColor=white)

</div>

<div align="center">
  <img src="resources/screenshots/hero_screenshot.jpeg" alt="İkinci ekran olarak kullanılan Android tablet" width="800"/>
</div>

## Hakkında

Side Screen, Android tabletinize gerçek ikinci ekran işlevi kazandırır. En düşük gecikme için USB-C kablosu veya tek seferlik QR eşleştirmesinden sonra kablosuz Wi-Fi bağlantısı kullanılabilir.

Apple Sidecar yalnızca iPad ile çalışırken Side Screen, Android tabletleri donanım hızlandırmalı H.265 aktarımı, USB'de 16 ms altı işlem hattı gecikmesi ve dokunmatik giriş desteğiyle macOS için genişletilmiş ekrana dönüştürür. Ekranı yansıtmak yerine gerçek bir sanal ekran oluşturur.

### Bu Repodaki Sürüm

Side Screen, [açık kaynak bir proje ve uygulamadır](https://github.com/tranvuongquocdat/SideScreen). Headless MacBook Tools içindeki özelleştirilmiş sürüm, headless kullanım için otomasyon ve auto-connect akışları ekler. Bu geliştirmeler; `sidescreen://auto-start-usb`, `--auto-start-usb` başlatma seçeneği, uygulama içi USB auto-start işleyişi ve [`Auto-SideScreen-USB`](../Auto-SideScreen-USB/README.tr.md) altındaki yardımcı launcher/UI otomasyon scriptlerini kapsar.

Ayrıntılı bilgi için [sidescreen.dev](https://sidescreen.dev) adresini ziyaret edin.

## Özellikler

### USB-C veya Kablosuz

- **USB-C:** En düşük gecikme için kabloyla bağlanır; `adb reverse` port yönlendirmesi otomatik kurulur.
- **Kablosuz:** Mac'teki QR kodu bir kez taratılır ve tablet sonraki açılışlarda otomatik bağlanır. 5 GHz Wi-Fi önerilir.
- Yetkilendirme anahtarı yerel olarak oluşturulur ve Mac'te tutulur. Erişimi iptal etmek için sıfırlanabilir.

### Gerçek Sanal Ekran

Mac'te gerçek bir sanal ekran oluşturur. Pencereleri normal bir monitörde olduğu gibi tablete sürükleyebilirsiniz.

<div align="center">
  <img src="resources/screenshots/feature_virtual_display.png" alt="macOS ekran ayarlarında sanal ekran" width="600"/>
</div>

### Düşük Gecikme

Mac'te donanım hızlandırmalı H.265 kodlama ve Android'de donanımsal çözme kullanır. Asenkron işlem hattı kareleri 30 ms altında iletebilir.

### Dokunmatik Giriş

Tablet ekranından macOS ile etkileşim kurulabilir. Dokunma tahmini, ağ gecikmesini telafi ederek dokunma ve sürüklemeleri daha doğal hale getirir.

### HiDPI, Oyun Modu ve Özelleştirme

- HiDPI modu iç çözünürlüğü 2 katına çıkararak metin ve simgeleri keskin gösterir.
- Gaming Boost; 1 Gbps bitrate, düşük gecikmeli kodlama ve 120 FPS ayarlarını uygular.
- Çözünürlük, kare hızı, bitrate ve kalite profilleri Mac uygulamasından değiştirilebilir.

## Gereksinimler

| | macOS Sunucu | Android İstemci |
|---|---|---|
| **İşletim sistemi** | macOS 13 Ventura veya üzeri | Android 8.0 / API 26 veya üzeri |
| **Donanım** | Apple Silicon veya Intel | H.265 donanımsal çözücü |
| **USB modu** | USB-C + `adb` | USB-C kablosu + USB hata ayıklama |
| **Kablosuz mod** | Tablet ile aynı Wi-Fi ağı; 5 GHz önerilir | QR tarama için kamera + Google Play Services |

## Kurulum

Son sürümü [GitHub Releases](https://github.com/tranvuongquocdat/SideScreen/releases) sayfasından indirin:

- **macOS:** `.dmg` dosyasını açıp Side Screen'i Applications klasörüne sürükleyin.
- **Android:** `.apk` dosyasını tablete kurun. Gerekirse bilinmeyen kaynaklara izin verin.

### macOS Gatekeeper

macOS uygulamanın hasarlı olduğunu söylerse Terminal'de şu komutu çalıştırın:

```bash
sudo xattr -cr /Applications/SideScreen.app
```

Uygulama Apple Developer sertifikasıyla notarize edilmediği için bu işlem gerekebilir.

### ADB

Mac uygulaması Android cihazla iletişim kurmak için `adb` kullanır:

```bash
brew install --cask android-platform-tools
```

### Kaynaktan Derleme

```bash
git clone https://github.com/tranvuongquocdat/SideScreen.git
cd SideScreen

# macOS
cd MacHost && swift build -c release

# Android
cd AndroidClient && ./gradlew assembleDebug
```

## Kullanım

### USB Modu

1. Tableti USB-C ile Mac'e bağlayın.
2. Mac'te menü çubuğunda çalışan Side Screen'i açın.
3. Tablette Side Screen'i açıp **USB** sekmesinde **Connect** düğmesine dokunun.
4. Pencereleri yeni ekrana sürükleyin.

### Kablosuz Mod

1. Mac'te Side Screen'i açıp **Wireless** sekmesine geçin; bir QR kod görünür.
2. Tablette **Wireless > Scan QR Code** seçeneğini açın, kamera izni verin ve kodu tarayın.
3. Tablet Mac'i hatırlar ve sonraki açılışlarda otomatik bağlanır.

İki cihaz aynı Wi-Fi ağında olmalıdır. Dinamik içerikteki titreşimi azaltmak için 5 GHz önerilir. Erişimi iptal etmek için Mac'te **Reset Token (forget all)** seçeneğini kullanın ve tabletleri yeniden eşleştirin.

USB modu çizim ve hızlı oyunlar için en düşük gecikmeyi sağlar. Kablosuz bağlantı ağ kalitesine bağlı olarak yaklaşık 10-50 ms ek gecikme oluşturabilir.

## Yapılandırma

| Ayar | Seçenekler | Varsayılan |
|---|---|---|
| Çözünürlük | 720p-8K, 30'dan fazla profil + özel | 1920x1200 |
| Kare hızı | 30, 60, 90, 120 FPS | 120 |
| Bitrate | 20-5000 Mbps | 1000 Mbps |
| Kalite | Ultra Low, Low, Medium, High | Ultra Low |
| HiDPI | Açık/Kapalı | Kapalı |
| Gaming Boost | Açık/Kapalı | Kapalı |
| Dokunmatik giriş | Açık/Kapalı | Açık |

## Sorun Giderme

### macOS uygulamanın hasarlı olduğunu söylüyor

```bash
sudo xattr -cr /Applications/SideScreen.app
```

Komutu çalıştırdıktan sonra uygulamayı yeniden açın.

### Android'de bağlantı reddediliyor

Mac uygulaması aktarım başlarken `adb reverse` işlemini otomatik yapar. Sorun sürerse `adb` kurulumunu ve cihazda USB hata ayıklamanın açık olduğunu kontrol edin.

### Gecikme veya takılma yüksek

- Çözünürlüğü veya kare hızını düşürün.
- Android cihazın H.265 donanımsal codec desteğini kontrol edin.
- USB modunda yalnızca şarj destekleyen kablo yerine kaliteli bir veri kablosu kullanın.
- Kablosuz modda iki cihazı da 5 GHz Wi-Fi ağına bağlayın; gerekirse 60 Hz'e düşürün.

### Kablosuz bağlantıda Mac'e ulaşılamıyor

- İki cihazın aynı ağda ve aynı alt ağda olduğunu kontrol edin.
- QR kodu taramadan önce Mac'te **Start** düğmesine basın.
- Mac'in IP adresi değiştiyse yeni QR kodu tarayın.
- macOS ilk kullanımda Yerel Ağ izni isterse izin verin.

### Yeniden eşleştirme gerekiyor

Yetkilendirme anahtarı sıfırlandıysa veya uygulama yeniden kurulduysa Android istemcide **Scan QR Code** ile yeni kodu tarayın.

### Sanal ekran görünmüyor

`System Settings > Privacy & Security > Screen Recording` altında Side Screen'e ekran kaydı izni verin.

## Katkıda Bulunma

Hata ve özellik önerileri için [Issues](https://github.com/tranvuongquocdat/SideScreen/issues) sayfasını kullanabilir, değişiklikler için pull request gönderebilirsiniz. Ayrıntılar [CONTRIBUTING.md](CONTRIBUTING.md) dosyasındadır.

## Lisans

[MIT Lisansı](LICENSE) kapsamında kişisel ve ticari kullanım için ücretsizdir.

<div align="center">

Tran Vuong Quoc Dat tarafından geliştirilmiştir.

[Hata Bildir](https://github.com/tranvuongquocdat/SideScreen/issues) · [Özellik İste](https://github.com/tranvuongquocdat/SideScreen/issues) · [Tartışmalar](https://github.com/tranvuongquocdat/SideScreen/discussions)

</div>
