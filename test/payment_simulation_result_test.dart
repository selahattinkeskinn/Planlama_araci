import 'package:flutter_application_1/models/payment_simulation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('başarılı sonuç ayrıştırılır', () {
    final result = PaymentSimulationResult.fromMap(<String, dynamic>{
      'status': 'success',
      'transactionId': 'SIM-ABC123-001',
      'total': 1250.0,
      'months': 6,
    });

    expect(result.approved, isTrue);
    expect(result.isReset, isFalse);
    expect(result.transactionId, 'SIM-ABC123-001');
    expect(result.total, 1250.0);
    expect(result.totalLabel, '1250,00 ₺');
    expect(result.months, 6);
  });

  test('reddedilen sonuç nedeniyle birlikte gösterilir', () {
    final result = PaymentSimulationResult.fromMap(<String, dynamic>{
      'status': 'failed',
      'reason': 'bank_rejected',
      'total': 99.5,
    });

    expect(result.approved, isFalse);
    expect(result.reasonLabel, 'banka reddi');
    expect(result.totalLabel, '99,50 ₺');
  });

  test('kullanıcı vazgeçmesi ayrı etiketlenir', () {
    final result = PaymentSimulationResult.fromMap(<String, dynamic>{
      'status': 'failed',
      'reason': 'user_cancelled',
    });

    expect(result.reasonLabel, 'kullanıcı vazgeçti');
    expect(result.totalLabel, '-');
  });

  test('sıfırlama mesajı tanınır', () {
    final result = PaymentSimulationResult.fromMap(<String, dynamic>{
      'status': 'reset',
    });

    expect(result.isReset, isTrue);
    expect(result.approved, isFalse);
  });

  test('eksik ve metin alanlar güvenli ayrıştırılır', () {
    final result = PaymentSimulationResult.fromMap(<String, dynamic>{
      'status': 'success',
      'total': '250,75',
      'months': '3',
    });

    expect(result.total, isNull); // virgüllü metin sayıya çevrilmez
    expect(result.months, 3);

    final empty = PaymentSimulationResult.fromMap(<String, dynamic>{});
    expect(empty.status, isNull);
    expect(empty.reasonLabel, 'bilinmeyen neden');
    expect(empty.totalLabel, '-');
  });
}
