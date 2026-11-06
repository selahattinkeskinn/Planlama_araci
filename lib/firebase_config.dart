import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseConfig {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;
  static FirebaseAppCheck? _appCheck;
  static FirebaseRemoteConfig? _remoteConfig;

  static Future<void> initialize() async {
    if (_app != null) return;

    _app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _auth = FirebaseAuth.instance;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _appCheck = FirebaseAppCheck.instance;
    _remoteConfig = FirebaseRemoteConfig.instance;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    }

    await _remoteConfig!.setDefaults(const {
      'app_maintenance_mode': false,
      'maintenance_message': 'Uygulama bakımda.',
      'feature_new_chat_enabled': true,
      'max_message_length': 1000,
    });

    await _remoteConfig!.fetchAndActivate();
  }

  static FirebaseAuth get auth => _auth!;
  static FirebaseAnalytics get analytics => _analytics!;
  static FirebaseCrashlytics get crashlytics => _crashlytics!;
  static FirebaseAppCheck get appCheck => _appCheck!;
  static FirebaseRemoteConfig get remoteConfig => _remoteConfig!;
  static bool get isInitialized => _app != null;
}
