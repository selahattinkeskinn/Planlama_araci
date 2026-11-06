import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    await _analytics.logEvent(
      name: name,
      parameters: params?.cast<String, Object>(),
    );
  }

  Future<void> logLogin(String method) async {
    await logEvent('login', params: {'method': method});
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
