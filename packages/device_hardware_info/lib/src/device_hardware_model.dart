/// Kotlin platform channel ile okunan donanım, kimlik ve root verileri.
library;

/// `device_hardware_info` kanalından dönen tüm donanım bilgileri.
class DeviceHardwareInfo {
  const DeviceHardwareInfo({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.board,
    required this.hardware,
    required this.bootloader,
    required this.buildId,
    required this.buildDisplay,
    required this.buildFingerprint,
    required this.buildTags,
    required this.buildType,
    required this.radioVersion,
    required this.socManufacturer,
    required this.socModel,
    required this.securityPatch,
    required this.kernelVersion,
    required this.javaVmVersion,
    required this.selinux,
    required this.imei,
    required this.imeiStatus,
    required this.imeiNote,
    required this.meid,
    required this.meidStatus,
    required this.serial,
    required this.serialStatus,
    required this.androidId,
    required this.cpuCores,
    required this.cpuAbi,
    required this.supportedAbis,
    required this.cpuHardware,
    required this.cpuMaxFreqKHz,
    required this.totalRamBytes,
    required this.availableRamBytes,
    required this.totalStorageBytes,
    required this.freeStorageBytes,
    required this.screenWidthPx,
    required this.screenHeightPx,
    required this.densityDpi,
    required this.refreshRate,
    required this.isRooted,
    required this.rootIndicators,
    required this.phonePermissionGranted,
    required this.isEmulator,
    required this.uptimeMillis,
  });

  final String manufacturer;
  final String brand;
  final String model;
  final String device;
  final String product;
  final String board;
  final String hardware;
  final String bootloader;

  final String buildId;
  final String buildDisplay;
  final String buildFingerprint;
  final String buildTags;
  final String buildType;
  final String radioVersion;

  final String? socManufacturer;
  final String? socModel;
  final String? securityPatch;
  final String? kernelVersion;
  final String? javaVmVersion;
  final String selinux;

  /// IMEI (Android 10+ için genellikle null).
  final String? imei;

  /// `ok`, `restricted`, `permission_required`, `unavailable`
  final String imeiStatus;

  /// IMEI okunamıyorsa nedeni.
  final String? imeiNote;

  final String? meid;
  final String meidStatus;

  /// Donanım seri numarası (Android 10+ için genellikle null).
  final String? serial;
  final String serialStatus;

  final String? androidId;

  final int cpuCores;
  final String? cpuAbi;
  final List<String> supportedAbis;
  final String? cpuHardware;
  final int? cpuMaxFreqKHz;

  final int totalRamBytes;
  final int availableRamBytes;
  final int totalStorageBytes;
  final int freeStorageBytes;

  final int screenWidthPx;
  final int screenHeightPx;
  final int densityDpi;
  final double refreshRate;

  final bool isRooted;
  final List<String> rootIndicators;
  final bool phonePermissionGranted;
  final bool isEmulator;
  final int uptimeMillis;

  /// Ekran çözünürlüğü, ör. "1080 × 2400".
  String get resolutionLabel => '$screenWidthPx × $screenHeightPx';

  /// CPU azami frekansı, ör. "2,4 GHz".
  String? get cpuMaxFreqLabel {
    final value = cpuMaxFreqKHz;
    if (value == null || value <= 0) return null;
    final ghz = value / 1000000;
    return '${ghz.toStringAsFixed(1).replaceAll('.', ',')} GHz';
  }

  /// IMEI yoksa durumunu açıklayan kısa etiket.
  String get imeiDisplay {
    if ((imei ?? '').trim().isNotEmpty) return imei!;
    switch (imeiStatus) {
      case 'restricted':
        return 'Kısıtlı (Android 10+)';
      case 'permission_required':
        return 'İzin gerekli';
      default:
        return imeiNote ?? 'Okunamadı';
    }
  }

  /// Seri numarası yoksa durumunu açıklayan kısa etiket.
  String get serialDisplay {
    if ((serial ?? '').trim().isNotEmpty) return serial!;
    switch (serialStatus) {
      case 'restricted':
        return 'Kısıtlı (Android 10+)';
      case 'permission_required':
        return 'İzin gerekli';
      default:
        return 'Okunamadı';
    }
  }

  factory DeviceHardwareInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceHardwareInfo(
      manufacturer: _str(map['manufacturer'], '-'),
      brand: _str(map['brand'], '-'),
      model: _str(map['model'], '-'),
      device: _str(map['device'], '-'),
      product: _str(map['product'], '-'),
      board: _str(map['board'], '-'),
      hardware: _str(map['hardware'], '-'),
      bootloader: _str(map['bootloader'], '-'),
      buildId: _str(map['buildId'], '-'),
      buildDisplay: _str(map['buildDisplay'], '-'),
      buildFingerprint: _str(map['buildFingerprint'], '-'),
      buildTags: _str(map['buildTags'], '-'),
      buildType: _str(map['buildType'], '-'),
      radioVersion: _str(map['radioVersion'], '-'),
      socManufacturer: _nullableStr(map['socManufacturer']),
      socModel: _nullableStr(map['socModel']),
      securityPatch: _nullableStr(map['securityPatch']),
      kernelVersion: _nullableStr(map['kernelVersion']),
      javaVmVersion: _nullableStr(map['javaVmVersion']),
      selinux: _str(map['selinux'], 'Bilinmiyor'),
      imei: _nullableStr(map['imei']),
      imeiStatus: _str(map['imeiStatus'], 'unavailable'),
      imeiNote: _nullableStr(map['imeiNote']),
      meid: _nullableStr(map['meid']),
      meidStatus: _str(map['meidStatus'], 'unavailable'),
      serial: _nullableStr(map['serial']),
      serialStatus: _str(map['serialStatus'], 'unavailable'),
      androidId: _nullableStr(map['androidId']),
      cpuCores: _int(map['cpuCores'], 0),
      cpuAbi: _nullableStr(map['cpuAbi']),
      supportedAbis: _strList(map['supportedAbis']),
      cpuHardware: _nullableStr(map['cpuHardware']),
      cpuMaxFreqKHz: _nullableInt(map['cpuMaxFreqKHz']),
      totalRamBytes: _int(map['totalRamBytes'], 0),
      availableRamBytes: _int(map['availableRamBytes'], 0),
      totalStorageBytes: _int(map['totalStorageBytes'], 0),
      freeStorageBytes: _int(map['freeStorageBytes'], 0),
      screenWidthPx: _int(map['screenWidthPx'], 0),
      screenHeightPx: _int(map['screenHeightPx'], 0),
      densityDpi: _int(map['densityDpi'], 0),
      refreshRate: _double(map['refreshRate'], 0),
      isRooted: map['isRooted'] == true,
      rootIndicators: _strList(map['rootIndicators']),
      phonePermissionGranted: map['phonePermissionGranted'] == true,
      isEmulator: map['isEmulator'] == true,
      uptimeMillis: _int(map['uptimeMillis'], 0),
    );
  }
}

String _str(Object? value, String fallback) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableStr(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

int _int(Object? value, int fallback) =>
    value is int ? value : (value is num ? value.toInt() : fallback);

int? _nullableInt(Object? value) =>
    value is int ? value : (value is num ? value.toInt() : null);

double _double(Object? value, double fallback) =>
    value is num ? value.toDouble() : fallback;

List<String> _strList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .where((item) => item != null)
      .map((item) => '$item')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
