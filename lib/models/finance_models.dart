import 'package:json_annotation/json_annotation.dart';

part 'finance_models.g.dart';

/// Frankfurter API cevabı: 1 TRY = X foreign birim.
@JsonSerializable()
class CurrencyResponse {
  const CurrencyResponse({
    required this.amount,
    required this.base,
    required this.date,
    required this.rates,
  });

  final double amount;
  final String base;
  final String date;
  final Map<String, double> rates;

  factory CurrencyResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrencyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CurrencyResponseToJson(this);
}
