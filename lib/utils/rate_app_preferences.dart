import 'package:quran/widgets/like_app_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateAppPreferences {
  static late SharedPreferences _preferences;

  static const storeKey = 'storeVisited';
  static const firstTime = 'firstTime';

  static Future init() async => _preferences = await SharedPreferences.getInstance().then(
        (preferences) => _preferences = preferences,
      );

  static Future setStoreVisitValue(bool storeVisited) async => await _preferences.setBool(storeKey, storeVisited);
  static Future setFirstTimeAppLaunch(bool storeVisited) async => await _preferences.setBool(firstTime, isFirstOpening);

  static bool getStoreVisitValue() => _preferences.getBool(storeKey) ?? false;
  static bool getFirstTimeLaunchValue() => _preferences.getBool(firstTime) ?? true;
}
