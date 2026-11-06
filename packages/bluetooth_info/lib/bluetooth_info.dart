/// Kotlin platform channel tabanlı Bluetooth bilgi eklentisi.
///
/// Kullanım:
/// ```dart
/// final info = await BluetoothInfoClient().getInfo();
/// print('${info.state} - ${info.name}');
/// ```
library;

export 'src/bluetooth_info_client.dart';
export 'src/bluetooth_info_model.dart';
