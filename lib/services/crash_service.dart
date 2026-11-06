import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  void recordError(dynamic error, StackTrace stackTrace, {bool fatal = false}) {
    _crashlytics.recordError(error, stackTrace, fatal: fatal);
  }

  void log(String message) {
    _crashlytics.log(message);
  }

  void setUser(String userId, {String? email, String? name}) {
    _crashlytics.setUserIdentifier(userId);
    if (email != null) {
      _crashlytics.setCustomKey('user_email', email);
    }
    if (name != null) {
      _crashlytics.setCustomKey('user_name', name);
    }
  }

  void setCustomKey(String key, dynamic value) {
    _crashlytics.setCustomKey(key, value);
  }

  Future<void> enable() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
  }
}
