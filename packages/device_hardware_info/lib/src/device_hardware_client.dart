import 'package:flutter/services.dart';

import 'device_hardware_model.dart';

/// Kullanıcıya gösterilebilir donanım bilgisi eklentisi hatası.
class DeviceHardwareException implements Exception {
  const DeviceHardwareException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// `device_hardware_info` platform kanalının Dart tarafı.
///
/// Kotlin tarafı:
/// `packages/device_hardware_info/android/.../DeviceHardwareInfoPlugin.kt`
class DeviceHardwareClient {
  DeviceHardwareClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('device_hardware_info');

  final MethodChannel _channel;

  /// Donanım numaralarını, IMEI/seri no ve root göstergelerini okur.
  Future<DeviceHardwareInfo> getInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getInfo');
      if (result == null) {
        throw const DeviceHardwareException('Donanım bilgisi alınamadı.');
      }
      return DeviceHardwareInfo.fromMap(result);
    } on MissingPluginException {
      throw const DeviceHardwareException(
        'Donanım bilgisi eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw DeviceHardwareException(_describe(error));
    }
  }

  /// Android 9 ve altında seri no/IMEI için READ_PHONE_STATE ister.
  Future<bool> requestPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } on MissingPluginException {
      throw const DeviceHardwareException(
        'Donanım bilgisi eklentisi bu platformda kullanılamıyor (yalnızca Android).',
      );
    } on PlatformException catch (error) {
      throw DeviceHardwareException(_describe(error));
    }
  }

  String _describe(PlatformException error) {
    switch (error.code) {
      case 'no_activity':
        return 'İzin istemek için aktif bir ekran gerekiyor.';
      case 'request_in_progress':
        return 'Zaten bir izin isteği sürüyor, biraz bekleyin.';
      default:
        final details = error.message;
        return details == null || details.isEmpty
            ? 'Donanım bilgisi hatası: ${error.code}'
            : 'Donanım bilgisi hatası: $details';
    }
  }
}
