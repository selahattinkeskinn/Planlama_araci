import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/finance_data.dart';
import 'finance_api.dart';

class FinanceService {
  static const _cacheBoxName = 'finance_cache';
  static const _cacheKey = 'finance_data';
  static const _cacheTimeKey = 'finance_cache_time';
  static const cacheTtlMinutes = 5;

  final FinanceApi _api;
  final Random _random = Random();

  FinanceService({Dio? dio}) : _api = FinanceApi(dio ?? Dio());

  /// Önceki gün kapanış fiyatını simüle eder (gerçek API'de geçmiş veri endpoint'i yoksa).
  double _previousClose(double current) {
    final changePct = (_random.nextDouble() * 4 - 2); // -2% ile +2% arasında
    return current / (1 + changePct / 100);
  }

  /// Son 1 saate aitmock haber zamanlaması üretir.
  String _newsTimeAgo(int minutesAgo) {
    if (minutesAgo < 1) return 'Şu an';
    if (minutesAgo == 1) return '1 dakika önce';
    return '$minutesAgo dakika önce';
  }

  Future<FinanceData> fetchLiveData({bool forceRefresh = false}) async {
    // 1) CACHE-FIRST: Hive'den kontrol et
    if (!forceRefresh) {
      try {
        final box = Hive.box(_cacheBoxName);
        final cachedJson = box.get(_cacheKey) as String?;
        final cachedAt = box.get(_cacheTimeKey) as int?;

        if (cachedJson != null && cachedAt != null) {
          final ageMinutes =
              (DateTime.now().millisecondsSinceEpoch - cachedAt) / (1000 * 60);
          if (ageMinutes < cacheTtlMinutes) {
            return FinanceData.fromJson(
              jsonDecode(cachedJson) as Map<String, dynamic>,
            );
          }
        }
      } catch (_) {
        // Cache okunamazsa ağa geç
      }
    }

    // 2) Ağdan çek
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.isNotEmpty &&
        connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      throw Exception('İnternet bağlantısı yok');
    }

    final response = await _api.getLatestRates("TRY").timeout(
      const Duration(seconds: 10),
    );

    final rates = response.rates;

    final currencyMap = <String, Map<String, String>>{
      'USD': {'name': 'Dolar', 'flag': '🇺🇸'},
      'EUR': {'name': 'Euro', 'flag': '🇪🇺'},
      'GBP': {'name': 'İngiliz Sterlini', 'flag': '🇬🇧'},
      'SAR': {'name': 'Suudi Riyali', 'flag': '🇸🇦'},
      'AED': {'name': 'BAE Dirhemi', 'flag': '🇦🇪'},
      'JPY': {'name': 'Japon Yeni', 'flag': '🇯🇵'},
      'CNY': {'name': 'Çin Yuanı', 'flag': '🇨🇳'},
      'CHF': {'name': 'İsviçre Frangi', 'flag': '🇨🇭'},
      'CAD': {'name': 'Kanada Doları', 'flag': '🇨🇦'},
      'AUD': {'name': 'Avustralya Doları', 'flag': '🇦🇺'},
    };

    final currencies = <CurrencyItem>[];

    for (final entry in currencyMap.entries) {
      final code = entry.key;
      final info = entry.value;
      final rawRate = rates[code];

      if (rawRate == null) continue;

      final buy = 1 / rawRate;
      final sell = buy * 1.003;
      final previousClose = _previousClose(buy);
      final change = ((buy - previousClose) / previousClose) * 100;

      currencies.add(
        CurrencyItem(
          code: code,
          name: info['name']!,
          buy: buy,
          sell: sell,
          change: change,
          flag: info['flag']!,
        ),
      );
    }

    currencies.sort((a, b) => a.code.compareTo(b.code));

    // 10 haber, son 1 saat içinde
    final newsTimes = <int>[2, 7, 13, 19, 28, 35, 42, 48, 53, 58];
    final newsTitles = <String>[
      'Fed faiz kararını açıkladı',
      'Altın fiyatlarında rekor seviye',
      'BIST 100 %1,2 yükseldi',
      'Petrol fiyatları düştü',
      'TCMB rezerv verileri yayımladı',
      'Dolar/TL seyirciliği arttı',
      'Borsa İstanbul yeşile döndü',
      'Gümüş fiyatlarıعلی%',
      'Euro bölgesi enflasyon verileri',
      'Asya borsaları karışık kapandı',
    ];
    final newsSources = <String>[
      'Bloomberg HT',
      'CNN Türk',
      'Haber Global',
      'Reuters',
      'Anadolu Ajansı',
      'Bloomberg HT',
      'CNN Türk',
      'Reuters',
      'Haber Global',
      'Bloomberg HT',
    ];
    final newsSummaries = <String>[
      'Amerika Merkez Bankası faizi %5.25 oranında sabit tuttu.',
      'Gram altın üç aylık en yüksek seviyeye geldi.',
      'Yabancı yatırımcı alışlarıyla endeks yeşil kapanıyor.',
      'Brent crude varil başına 82 dolara geriledi.',
      'Merkez bankası brüt Außen reservasını yayımladı.',
      'Döviz borsasında dolar/TL işlem hacmi arttı.',
      'BIST 100 endeksi gün sonu %1,2 artışla kapanıyor.',
      'Gümüş ons fiyatında yukarı yönlü hareket devam ediyor.',
      'Avrupa Merkez Bankası enflasyon raporu bekleniyor.',
      'Asya pasifik borsaları karışık performans sergiliyor.',
    ];

    final news = <FinancialNews>[];
    for (int i = 0; i < 10; i++) {
      news.add(
        FinancialNews(
          title: newsTitles[i],
          source: newsSources[i],
          time: _newsTimeAgo(newsTimes[i]),
          summary: newsSummaries[i],
        ),
      );
    }

    final usdItem = currencies.firstWhere(
      (c) => c.code == 'USD',
      orElse: () => const CurrencyItem(
        code: 'USD',
        name: 'Dolar',
        buy: 34.12,
        sell: 34.25,
        change: 0.0,
        flag: '🇺🇸',
      ),
    );

    final stats = FinanceStats(
      daily: StatItem(
        label: 'Günlük İşlem Hacmi',
        value: '${usdItem.buy.toStringAsFixed(2)} TL / USD',
        change: usdItem.change,
        isPositive: usdItem.isPositive,
      ),
      monthly: StatItem(
        label: 'Aylık Piyasa Değişimi',
        value: '${usdItem.change.abs().toStringAsFixed(1)} %',
        change: usdItem.change.abs(),
        isPositive: usdItem.isPositive,
      ),
      yearly: StatItem(
        label: 'Yıllık Getiri',
        value: '${(usdItem.change * 3).toStringAsFixed(1)} %',
        change: usdItem.change * 3,
        isPositive: usdItem.change >= 0,
      ),
    );

    final data = FinanceData(
      currencies: currencies,
      news: news,
      stats: stats,
    );

    // 3) CACHE'E YAZ
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(_cacheKey, jsonEncode(data.toJson()));
      await box.put(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}

    return data;
  }
}
