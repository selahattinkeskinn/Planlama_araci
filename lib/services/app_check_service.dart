import 'package:firebase_app_check/firebase_app_check.dart';

class AppCheckService {
  final FirebaseAppCheck _appCheck = FirebaseAppCheck.instance;

  Future<void> activate({bool debug = false}) async {
    if (debug) {
      await _appCheck.activate(androidProvider: AndroidProvider.debug);
    } else {
      await _appCheck.activate(androidProvider: AndroidProvider.playIntegrity);
    }
  }

  Future<String?> getToken() async {
    final token = await _appCheck.getToken();
    return token?.toString();
  }
}
