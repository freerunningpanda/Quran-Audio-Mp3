import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsProvider extends ChangeNotifier {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  Future<void> currentScreen({required String screenName}) async {
    await analytics.setCurrentScreen(screenName: screenName, screenClassOverride: '');
  }

  Future<void> sendAnalytics() async {
    await analytics.logEvent(
      name: 'load Screen',
      parameters: <String, dynamic>{},
    );
  }
}
