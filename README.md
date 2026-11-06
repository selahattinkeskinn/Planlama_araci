# Planlama & Demo Uygulaması

`flutter_application_1`, Flutter ile geliştirilmiş çok özellikli bir Android
demo uygulamasıdır. Sohbet/medya akışı, Hive tabanlı notlar, 3B animasyon,
canlı finans panosu, LLM sohbeti, Firebase servisleri, Kotlin platform
kanallarıyla Bluetooth ve donanım bilgisi ve **tamamen JavaScript ile yazılmış
6 aşamalı ödeme simülasyonu** içerir.

- **Paket adı:** `com.example.flutter_application_1`
- **Sürüm:** `0.1.0+1`
- **Dart SDK:** `^3.13.7`
- **Öncelikli hedef:** Android (iOS ve web dosyaları projede mevcut)

---

## Özellikler

### Sohbet ve medya
- Gradient temalı ana sayfa, Planlama Ajanı kartı ve sohbet listesi.
- Sohbet 1–4 arasında animasyonlu geçiş; listeden detaya `Hero` animasyonu.
- Mesajlara **resim, video ve ses** ekleme (dosya başına en fazla 40 MB).
  - Resimler balon içinde gösterilir, dokununca tam ekran yakınlaştırılır.
  - Videolar uygulama içi oynatıcıda oynar.
  - Ses dosyaları dalga formu ve süre göstergesiyle çalınır.
- Gönderilen medya mesajları listeye animasyonla eklenir.
- Medya dosyaları yalnızca oturum belleğinde tutulur; kalıcı depolama yoktur.

### Notlar (Hive)
- `hive_ce` ile yerel not depolama.
- `/notlar` listesi ve `/not/:key` detay sayfası.
- Not ekleme, düzenleme ve silme.


### Ağ durumu
- `connectivity_plus` ile bağlantı takibi.
- Ana sayfanın üstünde çevrimiçi/çevrimdışı banner'ı.

### Cihaz bilgisi — donanım, IMEI ve root
`packages/device_hardware_info` adlı **Kotlin platform channel** eklentisi ile:

- Üretici, marka, model, cihaz, ürün, kart ve bootloader bilgileri.
- **IMEI**, **MEID**, **seri numarası** ve **Android ID**.
- Build kimliği, parmak izi, etiketler, tip, radyo sürümü, güvenlik yaması.
- SoC üreticisi/modeli, CPU çekirdek sayısı, ABI listesi, CPU azami frekansı.
- Toplam/boş RAM, toplam/boş depolama.
- Ekran çözünürlüğü, yoğunluk (dpi) ve yenileme hızı.
- SELinux durumu, kernel sürümü, JVM sürümü ve çalışma süresi.
- **Root tespiti:** `su` yolları, Magisk/busybox izleri ve `test-keys` etiketi.
- `device_info_plus` verileriyle birlikte tek sayfada gösterim:
  `DONANIM NUMARALARI`, `DONANIM`, `KÖK / SİSTEM` bölümleri.

> Android 10 (API 29) ve üzerinde IMEI/seri numarası yalnızca sistem, operatör
> veya device-owner uygulamalarına açıktır. Normal uygulamalarda bu alanlar
> **“Kısıtlı (Android 10+)”** olarak gösterilir. Android 9 ve altında
> `READ_PHONE_STATE` izni istenir.

### Bluetooth bilgisi
`packages/bluetooth_info` adlı Kotlin eklentisi:

- `MethodChannel` ile adaptör durumu, ad, adres ve eşleşmiş cihazlar.
- `EventChannel` ile yakındaki cihaz taraması (ad, adres, RSSI).
- Android 12+ için `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`, Android 11 ve altı
  için konum izni akışı.
- Tarama ekranında TARA/DURDUR, ilerleme göstergesi ve RSSI sinyal çubukları.
- Emülatörde gerçek cihaz bulunamaz; başlatma/bitirme olayları doğrulanabilir.

### Finans panosu
- `Frankfurter` API'sinden canlı döviz kurları (API anahtarı gerekmez).
- Hive üzerinde 5 dakikalık önbellek; çevrimdışıyken son veriyi gösterme.
- Alış/satış fiyatı, günlük değişim ve istatistik kartları.
- Haber akışı simüle edilir; döviz kurları gerçektir.

### LLM sohbeti
- OpenAI uyumlu `/chat/completions` uç noktasına **akışlı (SSE)** istek.
- Hazır sağlayıcı ön ayarları:
  - OpenAI
  - Groq
  - OpenRouter
  - Google Gemini
  - Ollama (yerel)
- Sağlayıcıya göre model önerileri ve canlı model listesi.
- API anahtarı biçimiyle sağlayıcı uyuşmazlığı uyarısı (ör. Gemini adresi +
  OpenAI anahtarı).
- Ayarlar, oturumlar ve mesajlar Hive kutularında saklanır.

### Firebase
- Firebase Core, Auth, Analytics, Crashlytics, App Check, Remote Config ve
  Cloud Firestore bağımlılıkları.
- Global hata yakalayıcıları Crashlytics'e iletilir.
- App Check: debug'da debug sağlayıcısı, release'de Play Integrity.
- Remote Config varsayılanları: bakım modu, yeni sohbet özelliği ve mesaj
  uzunluğu limiti.

### Ödeme simülasyonu (6 aşama)
`assets/payment/payment_simulation.html` içinde HTML + CSS + JavaScript olarak
yazılmıştır. Flutter tarafı yalnızca `webview_flutter` ile barındırır.

1. **Kart bilgileri** — Luhn doğrulaması, kart markası (Visa/Mastercard/Amex/
   Troy), son kullanma tarihi ve CVV kontrolü.
2. **Fatura bilgileri** — ad soyad, e-posta, telefon, şehir ve adres.
3. **Tutar ve taksit** — 10 ₺ – 50.000 ₺ limiti, tek çekim veya 3/6/9/12
   taksit, vade farkı ve aylık ödeme hesabı, sözleşme onayı.
4. **SMS doğrulama** — 6 haneli simülasyon kodu, 3 deneme hakkı, kod yenileme.
5. **3D Secure** — banka seçimi ve **onay / red** simülasyon kontrolü.
6. **Sonuç** — işlem numarası, kart, banka, taksit, tarih ve toplam tutarlı
   makbuz; başarılı veya başarısız senaryo.

- JavaScript sonucu `PaymentBridge` kanalıyla Flutter'a JSON olarak bildirir.
- Flutter tarafında yeşil/kırmızı sonuç bandı ve snackbar gösterilir.
- “Yeni ödeme / Yeniden dene” akışı formu ve sonuç bandını sıfırlar.
- Gerçek kart bilgisi girilmemelidir; hiçbir veri kaydedilmez veya gönderilmez.

---

## Rotalar

Rotalar `lib/router/app_router.dart` içinde `auto_route` ile tanımlıdır.

| Yol | Sayfa | Açıklama |
| --- | --- | --- |
| `/` | `HomePage` | Ana sayfa |
| `/sohbetler` | `SohbetListesi` | Tüm sohbetler |
| `/sohbet/:id` | `SohbetDetay` | Sohbet ve medya |
| `/sohbet/device-info` | `SohbetDeviceInfoPage` | Donanım/IMEI/root |
| `/sohbet/app-network` | `SohbetAppNetworkInfoPage` | Uygulama ve ağ bilgisi |
| `/notlar` | `NotlarPage` | Hive not listesi |
| `/not/:key` | `NotDetayPage` | Not detayı |
| `/finans` | `FinanceDashboard` | Döviz ve istatistikler |
| `/llm` | `LlmChatPage` | LLM sohbeti |
| `/bluetooth` | `BluetoothInfoPage` | Bluetooth ve tarama |
| `/odeme` | `PaymentSimulationPage` | 6 aşamalı ödeme simülasyonu |
| `*` | — | `/` adresine yönlendirilir |

---

## Proje yapısı

```text
flutter_application_1/
├─ assets/
│  └─ payment/payment_simulation.html   # Tamamen JS ödeme simülasyonu
├─ lib/
│  ├─ blocs/                            # device_info, finance, llm_chat, ağ
│  ├─ media/                            # video oynatıcı (io/web)
│  ├─ models/                           # sohbet, finans, LLM, ödeme sonucu
│  ├─ pages/                            # tüm ekranlar
│  ├─ router/                           # auto_route tanımları + üretilen kod
│  ├─ services/                         # Firebase, LLM, finans, ayarlar
│  ├─ theme/                            # koyu gradient tema
│  ├─ utils/                            # biçimlendiriciler
│  ├─ widgets/                          # medya, küp, banner, kartlar
│  ├─ firebase_config.dart
│  └─ main.dart
├─ packages/
│  ├─ bluetooth_info/                   # Kotlin MethodChannel + EventChannel
│  └─ device_hardware_info/             # Kotlin donanım/IMEI/root kanalı
├─ test/                                # 37 test
└─ android/ · ios/ · web/               # platform dosyaları
```

---

## Platform kanalları

| Kanal | Metotlar | Amaç |
| --- | --- | --- |
| `device_hardware_info` | `getInfo`, `requestPermissions` | Donanım, IMEI/MEID/seri no, root |
| `bluetooth_info` | `getInfo`, `requestPermissions`, `startScan`, `stopScan` | Adaptör, eşleşmiş cihazlar, tarama |
| `bluetooth_info_events` | `EventChannel` | Tarama başladı/bitti/cihaz bulundu |

### Ödeme köprüsü

JavaScript → Flutter mesajları (`PaymentBridge.postMessage`):

```json
{ "status": "success", "transactionId": "SIM-...-...", "total": 1250, "months": 1 }
```

```json
{ "status": "failed", "reason": "bank_rejected", "total": 1250 }
```

```json
{ "status": "reset" }
```

Flutter tarafı bu mesajları `PaymentSimulationResult` modeline dönüştürür,
yinelenen bildirimleri engeller ve sonucu arayüzde gösterir.

---

## Kurulum ve çalıştırma

### Gereksinimler
- Flutter 3.47+ (Dart 3.13+)
- JDK 17
- Android SDK (compileSdk 36)
- Android Studio / emülatör veya fiziksel cihaz


## Testler

```sh
flutter test
```

Mevcut test dosyaları:

- `bluetooth_info_test.dart` — Bluetooth model/olay ayrıştırma
- `bluetooth_device_tile_test.dart` — RSSI ve cihaz kartı
- `device_hardware_info_test.dart` — donanım modeli, IMEI/seri etiketleri, root
- `payment_simulation_result_test.dart` — ödeme sonucu, red/sıfırlama etiketleri
- `llm_provider_test.dart` — sağlayıcı ve anahtar doğrulama
- `llm_chat_bloc_test.dart` — LLM sohbet durumları
- `media_message_test.dart` — medya mesajı gösterimi
- `router_test.dart` — rota geçişleri
- `sohbet_listesi_test.dart` — sohbet listesi

Son durum: **37/37 test geçiyor**, `flutter analyze` temiz.

---

## Bilinen sınırlamalar

- Android 10+ için IMEI/seri no okuma kısıtı (device owner/sistem uygulaması
  gerekir).
- Ödeme ekranı bir **simülasyondur**; gerçek ödeme ağına bağlanmaz.
- Medya mesajları yalnızca bellekte tutulur.
- LLM API anahtarları yerel Hive kutusunda saklanır; üretimde güvenli
  depolama/anahtar yönetimi önerilir.
- Finans haberleri simüle edilir; yalnızca döviz kurları canlıdır.

---

## Son eklenenler

- `device_hardware_info` Kotlin eklentisi: donanım numaraları, IMEI/MEID/seri
  no, Android ID, CPU/RAM/depolama/ekran ve root göstergeleri.
- Cihaz bilgisi sayfasına `DONANIM NUMARALARI`, `DONANIM`, `KÖK / SİSTEM`
  bölümleri; yenileme ve telefon izni akışı.
- Tamamen JavaScript ile 6 aşamalı ödeme simülasyonu ve `PaymentBridge`.
- `PaymentSimulationPage` (WebView), `/odeme` rotası ve ana sayfa kartı.
- `PaymentSimulationResult` modeli ve birim testleri.
