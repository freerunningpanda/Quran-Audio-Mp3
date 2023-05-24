import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:quran/utils/commonutils.dart';

import 'package:quran/utils/constants.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:quran/data/models/yearlyprayertiming.dart';
import 'package:quran/screens/home.dart';

import 'package:quran/screens/settings.dart';
import 'package:quran/widgets/reuseablewidgets.dart';

import 'res/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Map<int, String> methods = {
  1: "University of Islamic Sciences, Karachi",
  2: "Islamic Society of North America",
  3: "Muslim World League",
  4: "Umm Al-Qura University, Makkah",
  5: "Egyptian General Authority of Survey",
  7: "Institute of Geophysics, University of Tehran",
  8: "Gulf Region",
  9: "Kuwait",
  10: "Qatar",
  11: "Majlis Ugama Islam Singapura, Singapore",
  12: "Union Organization islamic de France",
  13: "Diyanet İşleri Başkanlığı, Turkey",
  14: "Spiritual Administration of Muslims of Russia",
  15: "Moonsighting Committee Worldwide (also requires shafaq paramteer)",
};

Map<int, String> schools = {0: 'Shafi', 1: 'Hanafi'};

final prayerProvider = riverpod.ChangeNotifierProvider.autoDispose(((ref) => PrayerController()));

class PrayerController with ChangeNotifier {
  PrayerController() {
    UserPrayerPreference userPrayerPreference =
        UserPrayerPreference.fromJson(json.decode(UC.hive.get(kUserPrayerPrefencees)));
    countryName = userPrayerPreference.country;
    method = userPrayerPreference.method;
    methodName = methods[method]!;

    oldMethod = userPrayerPreference.method;
    school = userPrayerPreference.school;
    schoolName = schools[school]!;
    oldSchool = userPrayerPreference.school;
    cityName = userPrayerPreference.city;
    oldCityName = userPrayerPreference.city;
    notificationsOn = UC.hive.get(kGetAdhanNotification, defaultValue: true);
    oldNotificationsOn = notificationsOn;
    notifyListeners();
  }
  bool notificationsOn = true;
  bool oldNotificationsOn = true;
  bool canChangeCity = false;
  int method = 3;
  int oldMethod = 3;
  String methodName = "Muslim World League";
  int school = 1;
  int oldSchool = 1;
  String schoolName = "Hanafi";
  String countryName = "";
  String cityName = "";
  String oldCityName = "";
  FocusNode focusNode = FocusNode();
  bool focus = false;
  bool settingsChanged = false;

  void notificationsOnOFF(bool _) {
    notificationsOn = !notificationsOn;
    ifSettingsChanged();
  }

  ifSettingsChanged() {
    if (oldMethod != method ||
        oldSchool != school ||
        oldCityName != cityName ||
        notificationsOn != oldNotificationsOn) {
      settingsChanged = true;
    } else {
      settingsChanged = false;
    }
    notifyListeners();
  }

  updateCanChangeCity() {
    canChangeCity = true;
    focus = true;
    focusNode.requestFocus();
    notifyListeners();
  }

  checkCity(String city) {
    cityName = city;
    canChangeCity = false;
    focus = false;
    focusNode.unfocus();
    ifSettingsChanged();
  }

  Future<bool> saveSettings(BuildContext context) async {
    if (notificationsOn) {
      UserPrayerPreference preference =
          UserPrayerPreference(country: countryName, city: cityName, method: method, school: school);
      showToast(context: context, content: const Text('Getting Prayer Times'), color: Colors.blue);
      String? newPrayerTimings = await compute(getYearlyPrayerTimings, preference);
      if (newPrayerTimings != null) {
        showToast(context: context, content: const Text('Settings Updated'), color: Colors.green);
        UC.hive.put(kYearlyPrayerTimings, newPrayerTimings);
        UC.hive.put(kUserPrayerPrefencees, json.encode(preference.toJson()));
        oldCityName = cityName;
        oldMethod = method;
        oldSchool = school;
        oldNotificationsOn = notificationsOn;
        ifSettingsChanged();

        generatePrayerNotifications(newPrayerTimings);
        return true;
      } else {
        showToast(context: context, content: Text(newPrayerTimings ?? 'Something went wrong'), color: Colors.red);
        return false;
      }
    } else {
      await UC.flutterLocalNotificationsPlugin?.cancelAll();
      notificationsOn = false;
      oldNotificationsOn = false;
      UC.hive.put(kGetAdhanNotification, false);
      ifSettingsChanged();
      return true;
    }
  }

  changeMethod(BuildContext context, String type) {
    String title = type;
    List<Widget> children = [];
    final theme = Theme.of(context);
    switch (type) {
      case "Method":
        children = methods.entries
            .map(
              (e) => CupertinoActionSheetAction(
                onPressed: () {
                  method = e.key;
                  methodName = e.value;

                  ifSettingsChanged();
                  Navigator.pop(context);
                },
                child: Text(
                  e.value,
                  style: theme.textTheme.headline6,
                ),
              ),
            )
            .toList();

        break;
      case "School":
        children = schools.entries
            .map(
              (e) => CupertinoActionSheetAction(
                onPressed: () {
                  school = e.key;
                  schoolName = e.value;
                  ifSettingsChanged();

                  Navigator.pop(context);
                },
                child: Text(
                  e.value,
                  style: theme.textTheme.headline6,
                ),
              ),
            )
            .toList();
        break;
      default:
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          title,
          style: theme.textTheme.headline5?.copyWith(color: theme.primaryColor),
        ),
        cancelButton: Material(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
          ),
        ),
        actions: children,
      ),
    );
  }
}

class PrayerSettingScreen extends riverpod.ConsumerWidget {
  static const id = "prayerSettingScreen";
  PrayerSettingScreen({Key? key}) : super(key: key);
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final theme = Theme.of(context);
    final pP = ref.watch(prayerProvider);
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.canvasColor,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: theme.canvasColor,
          centerTitle: true,
          title: Text(AppLocalizations.of(context)!.commonSettings),
        ),
        body: ListView(
          children: [
            EachSettingSwitchTab(
                iconData: Icons.notifications_active,
                onOff: pP.notificationsOnOFF,
                title: AppLocalizations.of(context)!.prayerNotifications,
                value: pP.notificationsOn,
                description:
                    "${AppLocalizations.of(context)!.prayerNotifications} ${pP.notificationsOn ? AppLocalizations.of(context)!.on : AppLocalizations.of(context)!.off}"),
            Visibility(
              visible: pP.notificationsOn,
              child: Column(
                children: [
                  Divider(
                    color: theme.shadowColor,
                  ),
                  ListTile(
                    onTap: () {
                      pP.changeMethod(context, AppLocalizations.of(context)!.method);
                    },
                    leading: Icon(
                      Icons.calculate,
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.method,
                      style: theme.textTheme.headline6,
                    ),
                    subtitle: Text(
                      pP.methodName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.primaryColorLight,
                      ),
                    ),
                  ),
                  Divider(
                    color: theme.shadowColor,
                  ),
                  ListTile(
                    onTap: () {
                      pP.changeMethod(context, AppLocalizations.of(context)!.school);
                    },
                    leading: Icon(
                      Icons.school,
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.school,
                      style: theme.textTheme.headline6,
                    ),
                    subtitle: Text(
                      pP.schoolName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.primaryColorLight,
                      ),
                    ),
                  ),
                  Divider(
                    color: theme.shadowColor,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.location_city,
                      color: theme.primaryColor,
                    ),
                    title: CupertinoTextField(
                      focusNode: pP.focusNode,
                      autofocus: pP.focus,
                      prefixMode: OverlayVisibilityMode.notEditing,
                      prefix: Text(
                        pP.cityName.titleCase,
                        style: theme.textTheme.headline6,
                      ),
                      readOnly: !pP.canChangeCity,
                      suffix: pP.canChangeCity
                          ? TextButton(
                              onPressed: () {
                                pP.checkCity(textEditingController.value.text);
                              },
                              child: Text(AppLocalizations.of(context)!.save),
                            )
                          : TextButton(
                              onPressed: () {
                                pP.updateCanChangeCity();
                              },
                              child: Text(
                                AppLocalizations.of(context)!.changeCity,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                      keyboardType: TextInputType.text,
                      controller: textEditingController,
                      onChanged: (String str) {},
                      onSubmitted: (value) {
                        pP.checkCity(value);
                      },
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.canvasColor),
                      ),
                    ),
                  ),
                  Divider(
                    color: theme.shadowColor,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.flag_circle_rounded,
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      pP.countryName,
                      style: theme.textTheme.headline6,
                    ),
                  ),
                  Divider(
                    color: theme.shadowColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: pP.settingsChanged
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.cancel,
                        size: 50,
                        color: AppColors.red,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        bool isChanged = await pP.saveSettings(context);
                        isChanged ? ref.refresh(homeProvider) : null;
                      },
                      icon: const Icon(
                        Icons.done,
                        size: 50,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ),
    );
  }
}
