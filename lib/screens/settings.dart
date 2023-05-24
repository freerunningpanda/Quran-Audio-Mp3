// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart' as provider;
import 'package:quran/utils/constants.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:quran/screens/prayersettings.dart';
import 'package:quran/screens/reciters.dart';
import 'package:quran/screens/audiotranslations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran/screens/texttranslations.dart';

import '../provider/banner_provider.dart';
import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'font_size_screen.dart';

import 'home.dart';
import 'subscribe_screen.dart';

final settingsProvider = riverpod.ChangeNotifierProvider.autoDispose(((ref) => SettingsController()));

class SettingsController with ChangeNotifier {
  double arabicFontSize = UC.uv.selectedArabicFontSize;
  double translationFontSize = UC.uv.selectedTranslationFontSize;
  bool getAdhanNotifications = UC.hive.get(kGetAdhanNotification, defaultValue: true);
  bool getAyahNotifications = UC.hive.get(kGetDailyAyahNotification, defaultValue: true);

  updateAdhanNotifications(bool value) {
    getAdhanNotifications = value;
    UC.hive.put(kGetAdhanNotification, value);

    notifyListeners();
    if (value) {
      generatePrayerNotifications(UC.hive.get(kYearlyPrayerTimings));
    } else {
      UC.flutterLocalNotificationsPlugin?.cancelAll();
    }
  }

  updateArabicFontSize(double newFontSize) {
    newFontSize = newFontSize.floorToDouble();
    arabicFontSize = newFontSize;
    UC.uv.updateSelectedArabicFontSize(newFontSize);
    notifyListeners();
  }

  updateTranslationFontSize(double newFontSize) {
    newFontSize = newFontSize.floorToDouble();
    translationFontSize = newFontSize;
    UC.uv.updateSelectedTranslationFontSize(newFontSize);
    notifyListeners();
  }
}

class SettingsScreen extends riverpod.ConsumerWidget {
  static const String id = 'settings';
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    context.read<RevenueCatProvider>().fetchOffer(context);
    context.read<RevenueCatProvider>().packages;
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: theme.canvasColor,
          centerTitle: true,
          title: Text(AppLocalizations.of(context)!.settings),
        ),
        body: ListView(
          children: [
            FutureBuilder(
              future: context.read<RevenueCatProvider>().getSubs(),
              builder: (_, snapshot) {
                final isAdLoad = context.read<InterstitialProvider>().isAdLoad;
                final bannerAdIsLoaded = context.read<BannerProvider>().bannerAdIsLoaded;
                final adManagerBannerAdIsLoaded = context.read<BannerProvider>().adManagerBannerAdIsLoaded;
                if (snapshot.hasData &&
                    snapshot.data == false &&
                    isAdLoad &&
                    bannerAdIsLoaded &&
                    adManagerBannerAdIsLoaded) {
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      ActionButton(
                        buttonColor: Colors.deepOrangeAccent,
                        textColor: theme.cardColor,
                        title: AppLocalizations.of(context)!.removeAds,
                        onTap: () => Navigator.of(context).pushNamed(SubscribeScreen.id),
                        size: 16,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
            InkWell(
              onTap: () {
                final isSubActive = context.read<RevenueCatProvider>().isSubActive;
                if (!isSubActive) {
                  showInterAtSixTime(context);
                }
                Navigator.pushNamed(context, RecitersScreen.id);
              },
              child: _SettingItem(
                title: AppLocalizations.of(context)!.changeReciters,
                description: AppLocalizations.of(context)!.aviableReciters,
                iconData: Icons.recent_actors,
              ),
            ),
            InkWell(
              onTap: () async {
                final isSubActive = context.read<RevenueCatProvider>().isSubActive;
                if (!isSubActive) {
                  showInterAtSixTime(context);
                }
                Navigator.pushNamed(context, PrayerSettingScreen.id);
              },
              child: _SettingItem(
                title: AppLocalizations.of(context)!.commonSettings,
                description: AppLocalizations.of(context)!.changeLocation,
                iconData: Icons.settings,
              ),
            ),
            InkWell(
              onTap: () async {
                final isSubActive = context.read<RevenueCatProvider>().isSubActive;
                if (!isSubActive) {
                  showInterAtSixTime(context);
                }
                Navigator.pushNamed(context, FontSizeScreen.id);
              },
              child: _SettingItem(
                title: AppLocalizations.of(context)!.changeFontSize,
                description: AppLocalizations.of(context)!.changeFontSize,
                iconData: Icons.text_fields,
              ),
            ),
            InkWell(
              onTap: () {
                final isSubActive = context.read<RevenueCatProvider>().isSubActive;
                if (!isSubActive) {
                  showInterAtSixTime(context);
                }
                Navigator.pushNamed(context, AyahTranslationsScreen.id);
              },
              child: _SettingItem(
                title: AppLocalizations.of(context)!.verseTranslations,
                description: '114 ${AppLocalizations.of(context)!.aviableTranslations}',
                iconData: Icons.translate,
              ),
            ),
            InkWell(
              onTap: () {
                final isSubActive = context.read<RevenueCatProvider>().isSubActive;
                if (!isSubActive) {
                  showInterAtSixTime(context);
                }
                Navigator.pushNamed(context, AudioTranslationsScreen.id);
              },
              child: _SettingItem(
                title: AppLocalizations.of(context)!.audioTranslations,
                description: '39 ${AppLocalizations.of(context)!.aviableTranslations}',
                iconData: Icons.hearing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String description;

  const _SettingItem({
    Key? key,
    required this.iconData,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 70,
        child: ListTile(
          trailing: Icon(
            iconData,
            size: 30,
            color: theme.primaryColor,
          ),
          title: Text(
            title,
            style: theme.textTheme.headline6,
          ),
          subtitle: description != ""
              ? Text(
                  description,
                  style: theme.textTheme.subtitle2?.copyWith(color: theme.primaryColorLight),
                )
              : SizedBox(),
        ),
      ),
    );
  }
}

class EachSettingSwitchTab extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String description;
  final bool value;
  final Function onOff;

  const EachSettingSwitchTab({
    Key? key,
    required this.iconData,
    required this.onOff,
    required this.title,
    required this.description,
    this.value = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 70,
        child: ListTile(
          leading: Icon(
            iconData,
            size: 30,
            color: theme.primaryColor,
          ),
          title: Text(
            title,
            style: theme.textTheme.headline6,
          ),
          subtitle: description != ""
              ? Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.primaryColorLight,
                  ),
                )
              : SizedBox(),
          trailing: CupertinoSwitch(
            value: value,
            onChanged: onOff as void Function(bool),
          ),
        ),
      ),
    );
  }
}
