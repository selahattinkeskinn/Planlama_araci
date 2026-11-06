# flutter_application_1

`auto_route` ile yönlendirme yapan, sohbet arayüzü modern ve animasyonlu bir
Flutter uygulaması.

## Özellikler

- Koyu, gradient temalı ana sayfa ve Planlama Ajanı kartı.
- `ListView.builder` ile çizilen "Tüm sohbetler" listesi (4 sohbet).
- Sohbet 1 / 2 / 3 / 4 arasında animasyonlu geçiş.
- Mesajlara **resim, video ve ses** ekleme.
  - Resimler balon içinde gösterilir, dokununca tam ekran yakınlaştırılır.
  - Videolar uygulama içi oynatıcıda oynar.
  - Ses dosyaları dalga formu ve süre göstergesiyle oynar.
- Gönderilen medya mesajları listeye animasyonla eklenir.
- Sayfa geçişleri: fade + hafif yukarı kayma + ölçek; listeden detaya sohbet
  ikonu `Hero` ile uçar.
- Sohbet 3'te `AnimationController` ile döndürülen 3B küp (`RotatingCube3D`).
- `hive_ce` ile yerel depolama: `/notlar` ve `/not/:key` sayfaları.
- `connectivity_plus` ile ağ durumu kontrolü (ana sayfanın üstünde banner).
- Ekleme sınırı: dosya başına 40 MB.

## Rotalar

| Yol | Sayfa |
| --- | --- |
| `/` | `HomePage` |
| `/sohbetler` | `SohbetListesi` (`ListView.builder`) |
| `/sohbet/:id` | `SohbetDetay` |
| Diğer yollar | `/` adresine yönlendirilir |

Rotalar `lib/router/app_router.dart` içinde tanımlıdır; sayfa sınıfları
`@RoutePage()` ile işaretlenir.

## Medya desteği

| Platform | Resim | Video | Ses |
| --- | --- | --- | --- |
| Android | ✅ | ✅ | ✅ |
| iOS | ✅ | ✅ | ✅ |
| Web | ✅ | ✅ | ✅ |

- Dosya seçimi `file_picker`, ses `audioplayers`, video `video_player` ile yapılır.
- Web'de video, bellekten oluşturulan blob adresiyle oynatılır.
- Masaüstü (Windows/macOS/Linux) hedefleri bu projede tanımlı değil; eklenirse
  `video_player` desteği platforma göre değişebilir.
- Medya dosyaları yalnızca oturum belleğinde tutulur; kalıcı depolama yoktur.

## Kod üretimi

Rota sınıfları `build_runner` ile üretilir. Yeni bir sayfa ekledikten veya rota
tanımını değiştirdikten sonra:

```sh
dart run build_runner build
```

Geliştirme sırasında sürekli üretim için:

```sh
dart run build_runner watch
```

## Çalıştırma

```sh
flutter run
```

Web üzerinde:

```sh
flutter run -d web-server --web-port 8123 --web-hostname 127.0.0.1
```

## Testler

```sh
flutter test
```
