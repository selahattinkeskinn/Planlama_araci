import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setDefaults(const {
      'app_maintenance_mode': false,
      'maintenance_message': 'Uygulama bakım modundadır.',
      'feature_new_chat_enabled': true,
      'max_message_length': 1000,
      'welcome_message': 'Merhaba, hoş geldiniz!',
    });

    await _remoteConfig.fetchAndActivate();
  }

  bool get maintenanceMode => _remoteConfig.getBool('app_maintenance_mode');
  String get maintenanceMessage => _remoteConfig.getString('maintenance_message');
  bool get newChatEnabled => _remoteConfig.getBool('feature_new_chat_enabled');
  int get maxMessageLength => _remoteConfig.getInt('max_message_length');
  String get welcomeMessage => _remoteConfig.getString('welcome_message');

  Future<void> refresh() async {
    await _remoteConfig.fetchAndActivate();
  }

  T getValue<T>(String key) {
    final value = _remoteConfig.getValue(key);
    if (T == bool) return value.asBool() as T;
    if (T == int) return value.asInt() as T;
    if (T == double) return value.asDouble() as T;
    return value.asString() as T;
  }
}
