import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class AppNetworkInfoEvent {
  const AppNetworkInfoEvent();
}

class LoadAppNetworkInfo extends AppNetworkInfoEvent {
  const LoadAppNetworkInfo();
}

abstract class AppNetworkInfoState {
  const AppNetworkInfoState();
}

class AppNetworkInfoInitial extends AppNetworkInfoState {
  const AppNetworkInfoInitial();
}

class AppNetworkInfoLoading extends AppNetworkInfoState {
  const AppNetworkInfoLoading();
}

class AppNetworkInfoLoaded extends AppNetworkInfoState {
  const AppNetworkInfoLoaded(this.data);

  final AppNetworkInfoData data;
}

class AppNetworkInfoError extends AppNetworkInfoState {
  const AppNetworkInfoError(this.message);

  final String message;
}

class AppNetworkInfoData {
  const AppNetworkInfoData({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.connectivityType,
    required this.isOnline,
    required this.lastChecked,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String connectivityType;
  final bool isOnline;
  final DateTime lastChecked;
}

class AppNetworkInfoBloc extends Bloc<AppNetworkInfoEvent, AppNetworkInfoState> {
  AppNetworkInfoBloc() : super(const AppNetworkInfoInitial()) {
    on<LoadAppNetworkInfo>((event, emit) async {
      emit(const AppNetworkInfoLoading());
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        final connectivityResult = await Connectivity().checkConnectivity();
        final isOnline = connectivityResult.isNotEmpty &&
            connectivityResult.any((r) => r != ConnectivityResult.none);
        final type = connectivityResult.isEmpty
            ? 'Bilinmiyor'
            : connectivityResult
                .map((e) => e.name)
                .join(' + ');

        emit(AppNetworkInfoLoaded(
          AppNetworkInfoData(
            appName: packageInfo.appName,
            packageName: packageInfo.packageName,
            version: packageInfo.version,
            buildNumber: packageInfo.buildNumber,
            connectivityType: type,
            isOnline: isOnline,
            lastChecked: DateTime.now(),
          ),
        ));
      } catch (e) {
        emit(AppNetworkInfoError('Uygulama/ağ bilgisi alınamadı: $e'));
      }
    });
  }
}
