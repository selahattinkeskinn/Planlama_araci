import 'package:device_hardware_info/device_hardware_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> fullMap() => <String, dynamic>{
    'manufacturer': 'Google',
    'brand': 'google',
    'model': 'Pixel 8',
    'device': 'shiba',
    'product': 'shiba',
    'board': 'shiba',
    'hardware': 'shiba',
    'bootloader': 'slider',
    'buildId': 'AP1A.240505.004',
    'buildDisplay': 'AP1A.240505.004',
    'buildFingerprint': 'google/shiba/shiba:14/AP1A:user/release-keys',
    'buildTags': 'release-keys',
    'buildType': 'user',
    'radioVersion': 'g5300q-240501',
    'socManufacturer': 'Google',
    'socModel': 'Tensor G3',
    'securityPatch': '2024-05-05',
    'kernelVersion': '6.1.25-android14',
    'javaVmVersion': '2.1.0',
    'selinux': 'Enforcing',
    'imei': '356789012345678',
    'imeiStatus': 'ok',
    'imeiNote': null,
    'meid': 'A1000012345678',
    'meidStatus': 'ok',
    'serial': 'SERIAL123456',
    'serialStatus': 'ok',
    'androidId': 'a1b2c3d4e5f60718',
    'cpuCores': 9,
    'cpuAbi': 'arm64-v8a',
    'supportedAbis': <dynamic>['arm64-v8a', 'armeabi-v7a'],
    'cpuHardware': 'Tensor G3',
    'cpuMaxFreqKHz': 2910000,
    'totalRamBytes': 8589934592,
    'availableRamBytes': 4294967296,
    'totalStorageBytes': 137438953472,
    'freeStorageBytes': 68719476736,
    'screenWidthPx': 1080,
    'screenHeightPx': 2400,
    'densityDpi': 420,
    'refreshRate': 120.0,
    'isRooted': false,
    'rootIndicators': <dynamic>[],
    'phonePermissionGranted': true,
    'isEmulator': false,
    'uptimeMillis': 123456,
  };

  test('donanım haritasını tüm alanlarla ayrıştırır', () {
    final info = DeviceHardwareInfo.fromMap(fullMap());

    expect(info.manufacturer, 'Google');
    expect(info.model, 'Pixel 8');
    expect(info.buildFingerprint, contains('release-keys'));
    expect(info.socModel, 'Tensor G3');
    expect(info.imei, '356789012345678');
    expect(info.imeiStatus, 'ok');
    expect(info.meid, 'A1000012345678');
    expect(info.serial, 'SERIAL123456');
    expect(info.androidId, 'a1b2c3d4e5f60718');
    expect(info.cpuCores, 9);
    expect(info.supportedAbis, <String>['arm64-v8a', 'armeabi-v7a']);
    expect(info.totalRamBytes, 8589934592);
    expect(info.refreshRate, 120.0);
    expect(info.isRooted, isFalse);
    expect(info.rootIndicators, isEmpty);
    expect(info.isEmulator, isFalse);
  });

  test('IMEI/seri no kısıtlıysa açıklayıcı etiket döner', () {
    final info = DeviceHardwareInfo.fromMap(<String, dynamic>{
      'imeiStatus': 'restricted',
      'serialStatus': 'restricted',
      'imeiNote': 'Android 10+ kısıtlaması',
    });

    expect(info.imei, isNull);
    expect(info.imeiDisplay, 'Kısıtlı (Android 10+)');
    expect(info.serialDisplay, 'Kısıtlı (Android 10+)');
    expect(info.imeiNote, 'Android 10+ kısıtlaması');
  });

  test('izin gerektiğinde uygun etiket döner', () {
    final info = DeviceHardwareInfo.fromMap(<String, dynamic>{
      'imeiStatus': 'permission_required',
      'serialStatus': 'permission_required',
    });

    expect(info.imeiDisplay, 'İzin gerekli');
    expect(info.serialDisplay, 'İzin gerekli');
  });

  test('okunamayan değerlerde güvenli varsayılanlar kullanılır', () {
    final info = DeviceHardwareInfo.fromMap(<String, dynamic>{});

    expect(info.model, '-');
    expect(info.imei, isNull);
    expect(info.imeiDisplay, 'Okunamadı');
    expect(info.serialDisplay, 'Okunamadı');
    expect(info.meid, isNull);
    expect(info.cpuCores, 0);
    expect(info.supportedAbis, isEmpty);
    expect(info.totalRamBytes, 0);
    expect(info.refreshRate, 0);
    expect(info.isRooted, isFalse);
    expect(info.rootIndicators, isEmpty);
    expect(info.selinux, 'Bilinmiyor');
  });

  test('root göstergeleri listeye dönüştürülür', () {
    final info = DeviceHardwareInfo.fromMap(<String, dynamic>{
      'isRooted': true,
      'rootIndicators': <dynamic>[
        'su: /system/xbin/su',
        'Build etiketi: test-keys',
      ],
    });

    expect(info.isRooted, isTrue);
    expect(info.rootIndicators, hasLength(2));
    expect(info.rootIndicators.first, contains('su'));
  });

  test('CPU frekansı ve ekran çözünürlüğü etiketlenir', () {
    final info = DeviceHardwareInfo.fromMap(fullMap());

    expect(info.cpuMaxFreqLabel, '2,9 GHz');
    expect(info.resolutionLabel, '1080 × 2400');
  });
}
