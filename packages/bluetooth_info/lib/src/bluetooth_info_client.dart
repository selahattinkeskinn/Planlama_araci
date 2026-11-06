import 'package:flutter/services.dart';

import 'bluetooth_info_model.dart';

/// Kullanıcıya gösterilebilir Bluetooth eklentisi hatası.
class BluetoothInfoException implements Exception {
  const BluetoothInfoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `bluetooth_info` platform kanalının Dart tarafı.
///
/// Kotlin tarafı: `packages/bluetooth_info/android/.../BluetoothInfoPlugin.kt`
class BluetoothInfoClient {
  BluetoothInfoClient({MethodChannel? channel, EventChannel? eventChannel})
    : _channel = channel ?? const MethodChannel('bluetooth_info'),
      _events =
          eventChannel ?? const EventChannel('bluetooth_info/discovery');

  final MethodChannel _channel;
  final EventChannel _events;

  /// Adaptör durumu, adı, adresi ve eşleşmiş cihazları okur.
  Future<BluetoothInfo> getInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getInfo');
      if (result == null) {
        throw const BluetoothInfoException('Bluetooth bilgisi alınamadı.');
      }
      return BluetoothInfo.fromMap(result);
    } on MissingPluginException {
      throw const BluetoothInfoException(
        'Bluetooth eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw BluetoothInfoException(_describe(error));
    }
  }

  /// Android 12+ için BLUETOOTH_CONNECT ve BLUETOOTH_SCAN izinlerini ister.
  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on MissingPluginException {
      throw const BluetoothInfoException(
        'Bluetooth eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw BluetoothInfoException(_describe(error));
    }
  }

  /// Yakındaki cihazları tarar.
  ///
  /// Akış dinlendiği sürece tarama sürer. Abonelik iptal edildiğinde
  /// tarama otomatik olarak durur.
  Stream<BluetoothScanEvent> scan() async* {
    try {
      final stream = _events.receiveBroadcastStream();
      await for (final raw in stream) {
        if (raw is Map) yield BluetoothScanEvent.fromMap(raw);
      }
    } on MissingPluginException {
      throw const BluetoothInfoException(
        'Bluetooth eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw BluetoothInfoException(_describe(error));
    }
  }

  /// Taramayı elle durdurur (akışı iptal etmek de yeterlidir).
  Future<void> stopScan() async {
    try {
      await _channel.invokeMethod<void>('stopDiscovery');
    } on MissingPluginException {
      throw const BluetoothInfoException(
        'Bluetooth eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw BluetoothInfoException(_describe(error));
    }
  }

  /// Sistemin Bluetooth ayarlar ekranını açar.
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      throw const BluetoothInfoException(
        'Bluetooth eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw BluetoothInfoException(_describe(error));
    }
  }

  String _describe(PlatformException error) {
    switch (error.code) {
      case 'permission_denied':
        return 'Bluetooth izni verilmedi. "İZİN VER" düğmesine basın.';
      case 'scan_permission_denied':
        return 'Yakındaki cihazları taramak için Bluetooth izni gerekiyor. '
            '"İZİN VER" düğmesine basın.';
      case 'bluetooth_off':
        return 'Bluetooth kapalı. Ayarlardan açıp tekrar deneyin.';
      case 'unsupported':
        return 'Bu cihazda Bluetooth adaptörü bulunmuyor.';
      case 'no_activity':
        return 'Bluetooth izni için aktif bir ekran gerekiyor.';
      case 'request_in_progress':
        return 'Zaten bir izin isteği sürüyor, biraz bekleyin.';
      case 'settings_error':
        return 'Bluetooth ayarları açılamadı.';
      default:
        final details = error.message;
        return details == null || details.isEmpty
            ? 'Bluetooth hatası: ${error.code}'
            : 'Bluetooth hatası: $details';
    }
  }
}
