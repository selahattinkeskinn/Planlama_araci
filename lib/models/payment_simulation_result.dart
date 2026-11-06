/// JavaScript ödeme simülasyonundan `PaymentBridge` kanalıyla gelen sonuç.
class PaymentSimulationResult {
  const PaymentSimulationResult({
    required this.status,
    required this.transactionId,
    required this.reason,
    required this.total,
    required this.months,
    required this.bank,
  });

  final String? status;
  final String? transactionId;
  final String? reason;
  final double? total;
  final int? months;
  final String? bank;

  bool get approved => status == 'success';

  bool get isReset => status == 'reset';

  String get reasonLabel {
    switch (reason) {
      case 'bank_rejected':
        return 'banka reddi';
      case 'user_cancelled':
        return 'kullanıcı vazgeçti';
      default:
        return reason ?? 'bilinmeyen neden';
    }
  }

  String get totalLabel {
    final value = total;
    if (value == null) return '-';
    final String formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$formatted ₺';
  }

  static PaymentSimulationResult fromMap(Map<String, dynamic> map) {
    return PaymentSimulationResult(
      status: _text(map['status']),
      transactionId: _text(map['transactionId']),
      reason: _text(map['reason']),
      total: _double(map['total']),
      months: _int(map['months']),
      bank: _text(map['bank']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
