import 'package:device_hardware_info/device_hardware_info.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeviceInfoEvent {
  const DeviceInfoEvent();
}

class LoadDeviceInfo extends DeviceInfoEvent {
  const LoadDeviceInfo();
}

/// Android 9 ve altında seri no/IMEI için telefon izni ister.
class RequestHardwarePermission extends DeviceInfoEvent {
  const RequestHardwarePermission();
}

abstract class DeviceInfoState {
  const DeviceInfoState();
}

class DeviceInfoInitial extends DeviceInfoState {
  const DeviceInfoInitial();
}

class DeviceInfoLoading extends DeviceInfoState {
  const DeviceInfoLoading();
}

class DeviceInfoLoaded extends DeviceInfoState {
  const DeviceInfoLoaded(this.data);

  final DeviceInfoData data;
}

class DeviceInfoError extends DeviceInfoState {
  const DeviceInfoError(this.message);

  final String message;
}

class DeviceInfoData {
  const DeviceInfoData({
    required this.model,
    required this.manufacturer,
    required this.osName,
    required this.osVersion,
    required this.sdkInt,
    required this.deviceName,
    required this.isEmulator,
    this.hardware,
    this.hardwareError,
  });

  final String model;
  final String manufacturer;
  final String osName;
  final String osVersion;
  final int sdkInt;
  final String deviceName;
  final bool isEmulator;

  /// Kotlin platform channel'dan gelen donanım numaraları ve root verileri.
  ///
  /// Eklenti kullanılamıyorsa (ör. Android dışı platform) null olur.
  final DeviceHardwareInfo? hardware;

  /// Donanım bilgisi alınamadıysa nedeni.
  final String? hardwareError;

  @override
  String toString() {
    return 'DeviceInfoData(model: $model, manufacturer: $manufacturer, '
        'osName: $osName, osVersion: $osVersion, sdkInt: $sdkInt, '
        'deviceName: $deviceName, isEmulator: $isEmulator, '
        'hardware: ${hardware != null})';
  }
}

class DeviceInfoBloc extends Bloc<DeviceInfoEvent, DeviceInfoState> {
  DeviceInfoBloc({DeviceHardwareClient? hardwareClient})
    : _hardwareClient = hardwareClient ?? DeviceHardwareClient(),
      super(const DeviceInfoInitial()) {
    on<LoadDeviceInfo>((event, emit) async {
      emit(const DeviceInfoLoading());
      try {
        final info = DeviceInfoPlugin();
        final androidInfo = await info.androidInfo;

        DeviceHardwareInfo? hardware;
        String? hardwareError;
        try {
          hardware = await _hardwareClient.getInfo();
        } on DeviceHardwareException catch (error) {
          hardwareError = error.message;
        } catch (error) {
          hardwareError = 'Donanım bilgisi alınamadı: $error';
        }

        emit(
          DeviceInfoLoaded(
            DeviceInfoData(
              model: androidInfo.model,
              manufacturer: androidInfo.manufacturer,
              osName: 'Android',
              osVersion: androidInfo.version.release,
              sdkInt: androidInfo.version.sdkInt,
              deviceName: androidInfo.device,
              isEmulator: androidInfo.isPhysicalDevice == false,
              hardware: hardware,
              hardwareError: hardwareError,
            ),
          ),
        );
      } catch (e) {
        emit(DeviceInfoError('Cihaz bilgisi alınamadı: $e'));
      }
    });

    on<RequestHardwarePermission>((event, emit) async {
      try {
        await _hardwareClient.requestPermissions();
      } catch (_) {
        // İzin verilmese de bilgiler yeniden yüklenir.
      }
      add(const LoadDeviceInfo());
    });
  }

  final DeviceHardwareClient _hardwareClient;
}
