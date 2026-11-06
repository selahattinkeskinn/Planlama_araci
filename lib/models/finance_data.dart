class CurrencyItem {
  const CurrencyItem({
    required this.code,
    required this.name,
    required this.buy,
    required this.sell,
    required this.change,
    required this.flag,
  });

  final String code;
  final String name;
  final double buy;
  final double sell;
  final double change;
  final String flag;

  bool get isPositive => change >= 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
        'buy': buy,
        'sell': sell,
        'change': change,
        'flag': flag,
      };

  factory CurrencyItem.fromJson(Map<String, dynamic> json) => CurrencyItem(
        code: json['code'] as String,
        name: json['name'] as String,
        buy: (json['buy'] as num).toDouble(),
        sell: (json['sell'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        flag: json['flag'] as String,
      );
}

class FinancialNews {
  const FinancialNews({
    required this.title,
    required this.source,
    required this.time,
    required this.summary,
    this.imageUrl,
  });

  final String title;
  final String source;
  final String time;
  final String summary;
  final String? imageUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'source': source,
        'time': time,
        'summary': summary,
        'imageUrl': imageUrl,
      };

  factory FinancialNews.fromJson(Map<String, dynamic> json) => FinancialNews(
        title: json['title'] as String,
        source: json['source'] as String,
        time: json['time'] as String,
        summary: json['summary'] as String,
        imageUrl: json['imageUrl'] as String?,
      );
}

class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  final String label;
  final String value;
  final double change;
  final bool isPositive;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'value': value,
        'change': change,
        'isPositive': isPositive,
      };

  factory StatItem.fromJson(Map<String, dynamic> json) => StatItem(
        label: json['label'] as String,
        value: json['value'] as String,
        change: (json['change'] as num).toDouble(),
        isPositive: json['isPositive'] as bool,
      );
}

class FinanceStats {
  const FinanceStats({
    required this.daily,
    required this.monthly,
    required this.yearly,
  });

  final StatItem daily;
  final StatItem monthly;
  final StatItem yearly;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'daily': daily.toJson(),
        'monthly': monthly.toJson(),
        'yearly': yearly.toJson(),
      };

  factory FinanceStats.fromJson(Map<String, dynamic> json) => FinanceStats(
        daily: StatItem.fromJson(json['daily'] as Map<String, dynamic>),
        monthly: StatItem.fromJson(json['monthly'] as Map<String, dynamic>),
        yearly: StatItem.fromJson(json['yearly'] as Map<String, dynamic>),
      );
}

class FinanceData {
  const FinanceData({
    required this.currencies,
    required this.news,
    required this.stats,
  });

  final List<CurrencyItem> currencies;
  final List<FinancialNews> news;
  final FinanceStats stats;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currencies': currencies.map((e) => e.toJson()).toList(),
        'news': news.map((e) => e.toJson()).toList(),
        'stats': stats.toJson(),
      };

  factory FinanceData.fromJson(Map<String, dynamic> json) => FinanceData(
        currencies: (json['currencies'] as List)
            .map((e) => CurrencyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        news: (json['news'] as List)
            .map((e) => FinancialNews.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: FinanceStats.fromJson(json['stats'] as Map<String, dynamic>),
      );
}
