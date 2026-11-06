/// Kotlin platform channel ile okunan Bluetooth verileri.
library;

/// Bir Bluetooth cihazı (eşleşmiş veya yakında bulunan).
class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
    required this.type,
    required this.bonded,
    this.rssi = 0,
  });

  final String name;
  final String address;
  final String type;
  final bool bonded;

  /// Sinyal gücü (dBm). Tarama dışında 0'dır.
  final int rssi;

  bool get hasSignal => rssi < 0;

  /// Sinyal gücüne göre kısa etiket.
  String get signalLabel {
    if (!hasSignal) return '-';
    if (rssi >= -60) return 'Güçlü';
    if (rssi >= -75) return 'Orta';
    return 'Zayıf';
  }

  factory BluetoothDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    final rawName = map['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName
        : 'Bilinmeyen cihaz';
    return BluetoothDeviceInfo(
      name: name,
      address: '${map['address'] ?? '-'}',
      type: '${map['type'] ?? 'Bilinmiyor'}',
      bonded: map['bonded'] == true,
      rssi: map['rssi'] is int ? map['rssi'] as int : 0,
    );
  }
}

/// Tarama olayının türü.
enum BluetoothScanEventType { started, device, finished }

/// `bluetooth_info/discovery` kanalından gelen olay.
class BluetoothScanEvent {
  const BluetoothScanEvent(this.type, [this.device]);

  final BluetoothScanEventType type;
  final BluetoothDeviceInfo? device;

  factory BluetoothScanEvent.fromMap(Map<dynamic, dynamic> map) {
    switch ('${map['type']}') {
      case 'started':
        return const BluetoothScanEvent(BluetoothScanEventType.started);
      case 'finished':
        return const BluetoothScanEvent(BluetoothScanEventType.finished);
      default:
        final rawDevice = map['device'];
        return BluetoothScanEvent(
          BluetoothScanEventType.device,
          rawDevice is Map ? BluetoothDeviceInfo.fromMap(rawDevice) : null,
        );
    }
  }
}

/// Bluetooth adaptörünün anlık durumu.
class BluetoothInfo {
  const BluetoothInfo({
    required this.supported,
    required this.enabled,
    required this.state,
    required this.stateCode,
    required this.permissionGranted,
    required this.scanPermissionGranted,
    required this.discovering,
    required this.androidVersion,
    required this.deviceModel,
    required this.bondedDevices,
    this.name,
    this.address,
    this.permissionError,
  });

  /// Cihazda Bluetooth adaptörü var mı?
  final bool supported;

  /// Adaptör açık mı?
  final bool enabled;

  /// "Açık", "Kapalı", "Açılıyor", "Kapanıyor", "Bilinmiyor"
  final String state;

  /// Ham [android.bluetooth.BluetoothAdapter] durum kodu.
  final int stateCode;

  /// Android 12+ için BLUETOOTH_CONNECT izni verildi mi?
  final bool permissionGranted;

  /// Tarama (BLUETOOTH_SCAN / konum) izni verildi mi?
  final bool scanPermissionGranted;

  /// Şu anda tarama sürüyor mu?
  final bool discovering;

  final String androidVersion;
  final String deviceModel;

  /// Adaptör adı (izin gerektirir).
  final String? name;

  /// Adaptör MAC adresi (izin gerektirir).
  final String? address;

  final List<BluetoothDeviceInfo> bondedDevices;

  /// İzin engeli nedeniyle okunamayan alanlar için açıklama.
  final String? permissionError;

  bool get hasName => (name ?? '').trim().isNotEmpty;

  factory BluetoothInfo.fromMap(Map<dynamic, dynamic> map) {
    final rawDevices = map['bondedDevices'];
    final devices = <BluetoothDeviceInfo>[];
    if (rawDevices is List) {
      for (final item in rawDevices) {
        if (item is Map) devices.add(BluetoothDeviceInfo.fromMap(item));
      }
    }

    return BluetoothInfo(
      supported: map['supported'] == true,
      enabled: map['enabled'] == true,
      state: '${map['state'] ?? 'Bilinmiyor'}',
      stateCode: map['stateCode'] is int ? map['stateCode'] as int : -1,
      permissionGranted: map['permissionGranted'] == true,
      scanPermissionGranted: map['scanPermissionGranted'] == true,
      discovering: map['discovering'] == true,
      androidVersion: '${map['androidVersion'] ?? '-'}',
      deviceModel: '${map['deviceModel'] ?? '-'}',
      name: map['name'] as String?,
      address: map['address'] as String?,
      bondedDevices: devices,
      permissionError: map['permissionError'] as String?,
    );
  }
}
