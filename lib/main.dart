import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/analytics_service.dart';
import 'services/crash_service.dart';
import 'services/remote_config_service.dart';
import 'services/app_check_service.dart';

final AuthService authService = AuthService();
final AnalyticsService analyticsService = AnalyticsService();
final CrashService crashService = CrashService();
final RemoteConfigService remoteConfigService = RemoteConfigService();
final AppCheckService appCheckService = AppCheckService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    Hive.init(null);
  } else {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
  }
  await Hive.openBox('notes');
  await Hive.openBox('finance_cache');
  await Hive.openBox('llm_messages');
  await Hive.openBox('llm_sessions');
  await Hive.openBox('llm_settings');

  await FirebaseConfig.initialize();
  await remoteConfigService.initialize();
  await appCheckService.activate(debug: kDebugMode);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _router = AppRouter();

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      authService.authStateChanges.listen((user) {
        if (user != null) {
          crashService.setUser(user.uid, email: user.email);
          analyticsService.setUserId(user.uid);
        }
      });
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sohbetler',
      theme: buildAppTheme(),
      routerConfig: _router.config(),
    );
  }
}
