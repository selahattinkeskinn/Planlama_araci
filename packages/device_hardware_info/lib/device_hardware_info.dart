/// Kotlin platform channel tabanlı donanım bilgisi eklentisi.
///
/// Kullanım:
/// ```dart
/// final hardware = await DeviceHardwareClient().getInfo();
/// print('${hardware.imeiDisplay} · ${hardware.totalRamBytes}');
/// ```
library;

export 'src/device_hardware_client.dart';
export 'src/device_hardware_model.dart';
