import 'package:bluetooth_info/bluetooth_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/widgets/bluetooth_device_tile.dart';

BluetoothDeviceInfo _device({
  String name = 'Kulaklık',
  int rssi = 0,
  bool bonded = false,
}) {
  return BluetoothDeviceInfo(
    name: name,
    address: '11:22:33:44:55:66',
    type: 'Klasik',
    bonded: bonded,
    rssi: rssi,
  );
}

void main() {
  testWidgets('tarama sonucunda ad, adres ve dBm gösterilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BluetoothDeviceTile(device: _device(rssi: -62), showSignal: true),
        ),
      ),
    );

    expect(find.text('Kulaklık'), findsOneWidget);
    expect(find.text('11:22:33:44:55:66 · Klasik'), findsOneWidget);
    expect(find.text('-62 dBm'), findsOneWidget);
    // Eşleşme simgesi tarama görünümünde çizilmez.
    expect(find.byIcon(Icons.link_rounded), findsNothing);
  });

  testWidgets('sinyal yoksa tire gösterilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BluetoothDeviceTile(device: _device(), showSignal: true),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('eşleşmiş cihazda bağlantı simgesi gösterilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BluetoothDeviceTile(device: _device(bonded: true)),
        ),
      ),
    );

    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });
}
