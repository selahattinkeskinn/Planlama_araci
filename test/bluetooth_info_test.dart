import 'package:bluetooth_info/bluetooth_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BluetoothInfo platform kanal haritasını ayrıştırır', () {
    final info = BluetoothInfo.fromMap(<String, dynamic>{
      'supported': true,
      'enabled': true,
      'state': 'Açık',
      'stateCode': 12,
      'permissionGranted': true,
      'androidVersion': 'Android 15 (API 35)',
      'deviceModel': 'Google Pixel 5',
      'name': 'Pixel 5',
      'address': 'AA:BB:CC:DD:EE:FF',
      'bondedDevices': <dynamic>[
        <String, dynamic>{
          'name': 'Kulaklık',
          'address': '11:22:33:44:55:66',
          'type': 'Klasik',
          'bonded': true,
        },
      ],
    });

    expect(info.supported, isTrue);
    expect(info.enabled, isTrue);
    expect(info.state, 'Açık');
    expect(info.stateCode, 12);
    expect(info.hasName, isTrue);
    expect(info.name, 'Pixel 5');
    expect(info.address, 'AA:BB:CC:DD:EE:FF');
    expect(info.bondedDevices, hasLength(1));
    expect(info.bondedDevices.single.name, 'Kulaklık');
    expect(info.bondedDevices.single.bonded, isTrue);
  });

  test('izin verilmediğinde ad/adres okunmaz, liste boş kalır', () {
    final info = BluetoothInfo.fromMap(<String, dynamic>{
      'supported': true,
      'enabled': false,
      'state': 'Kapalı',
      'stateCode': 10,
      'permissionGranted': false,
      'androidVersion': 'Android 13 (API 33)',
      'deviceModel': 'Emulator',
      'bondedDevices': <dynamic>[],
    });

    expect(info.permissionGranted, isFalse);
    expect(info.hasName, isFalse);
    expect(info.address, isNull);
    expect(info.bondedDevices, isEmpty);
  });

  test('eksik alanlar güvenli varsayılanlara düşer', () {
    final info = BluetoothInfo.fromMap(<String, dynamic>{});

    expect(info.supported, isFalse);
    expect(info.enabled, isFalse);
    expect(info.state, 'Bilinmiyor');
    expect(info.stateCode, -1);
    expect(info.androidVersion, '-');
    expect(info.bondedDevices, isEmpty);
    expect(info.scanPermissionGranted, isFalse);
    expect(info.discovering, isFalse);
  });

  test('tarama izni ve tarama durumu haritadan okunur', () {
    final info = BluetoothInfo.fromMap(<String, dynamic>{
      'supported': true,
      'enabled': true,
      'permissionGranted': true,
      'scanPermissionGranted': true,
      'discovering': true,
    });

    expect(info.scanPermissionGranted, isTrue);
    expect(info.discovering, isTrue);
  });

  test('RSSI sinyal seviyesi ve etiketi hesaplanır', () {
    BluetoothDeviceInfo device(int rssi) => BluetoothDeviceInfo.fromMap(
      <String, dynamic>{
        'name': 'Kulaklık',
        'address': 'AA:BB:CC:DD:EE:FF',
        'type': 'Klasik',
        'bonded': false,
        'rssi': rssi,
      },
    );

    expect(device(-45).hasSignal, isTrue);
    expect(device(-45).signalLabel, 'Güçlü');
    expect(device(-70).signalLabel, 'Orta');
    expect(device(-88).signalLabel, 'Zayıf');
    expect(device(0).hasSignal, isFalse);
    expect(device(0).signalLabel, '-');
  });

  test('tarama olayları türe göre ayrıştırılır', () {
    final started = BluetoothScanEvent.fromMap(<String, dynamic>{
      'type': 'started',
    });
    expect(started.type, BluetoothScanEventType.started);
    expect(started.device, isNull);

    final finished = BluetoothScanEvent.fromMap(<String, dynamic>{
      'type': 'finished',
    });
    expect(finished.type, BluetoothScanEventType.finished);

    final found = BluetoothScanEvent.fromMap(<String, dynamic>{
      'type': 'device',
      'device': <String, dynamic>{
        'name': 'Telefon',
        'address': '11:22:33:44:55:66',
        'type': 'Çift mod',
        'bonded': false,
        'rssi': -62,
      },
    });
    expect(found.type, BluetoothScanEventType.device);
    expect(found.device, isNotNull);
    expect(found.device!.name, 'Telefon');
    expect(found.device!.rssi, -62);
  });
}
