import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/database/isarschema.dart';
import 'package:http/http.dart';
import 'package:quran/main.dart';
import 'package:quran/data/models/jsonmodeltranslation.dart';
import 'package:quran/data/models/yearlyprayertiming.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../provider/interstitial_provider.dart';
import '../screens/home.dart';
import '../screens/res/app_strings.dart';
import '../screens/subscribe_screen.dart';
import '../widgets/like_app_widget.dart';
import 'utils.dart';

Duration initialDelay() {
  DateTime now = DateTime.now();
  DateTime tomorrow = now.add(const Duration(days: 1));
  DateTime morning = DateTime(
    tomorrow.year,
    tomorrow.month,
    tomorrow.day,
    7,
    50,
  );

  return morning.difference(now);
}

Future<List<List<Ayah>>> getTextAndTranslationAyahsBySurahNo(int surahNo) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );
  List<Ayah> surahTranslationText = isar.ayahs
      .filter()
      .chapterNoEqualTo(surahNo)
      .and()
      .languageEqualTo(isar.textTranslations.filter().isSelectedEqualTo(true).findFirstSync()!.identifier)
      .findAllSync();

  List<Ayah> surahText = isar.ayahs.filter().chapterNoEqualTo(surahNo).and().languageEqualTo(kArabicText).findAllSync();
  return [surahText, surahTranslationText];
}

Future<List<Ayah>> getTextBySurahNo(int surahNo) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  List<Ayah> surahText =
      await isar.ayahs.filter().chapterNoEqualTo(surahNo).and().languageEqualTo(kArabicText).findAll();
  return surahText;
}

Future<List<dynamic>> getRandomAyah(bool _) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  int randomNumber = Random().nextInt(6236);

  Ayah translation = isar.ayahs
      .filter()
      .numberEqualTo(randomNumber)
      .and()
      .languageEqualTo(isar.textTranslations.filter().isSelectedEqualTo(true).findFirstSync()!.identifier)
      .findFirstSync()!;
  Ayah arabic = isar.ayahs.filter().numberEqualTo(randomNumber).and().languageEqualTo(kArabicText).findFirstSync()!;

  Surah surah = isar.surahs.filter().numberEqualTo(arabic.chapterNo).findFirstSync()!;
  return [arabic, translation, surah];
}

Future<List<Surah>> getAllSurahs(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  return isar.surahs.where().sortByNumber().findAllSync();
}

Future<List<Surah>> getLastRecitedSurahs(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  return isar.surahs.filter().lastRecitedIsNotNull().sortByLastRecitedDesc().findAllSync();
}

Future<List<Surah>> getBookmarkedSurahs(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  return isar.surahs.filter().bookmarkedEqualTo(true).findAllSync();
}

Future<List<Reciter>> getBookmarkedReciters(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  return isar.reciters.filter().bookmarkedEqualTo(true).findAllSync();
}

Future<List<TextTranslation>> getBookmarkedTextTranslations(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  return isar.textTranslations.filter().bookmarkedEqualTo(true).findAllSync();
}

Future<List<List<Ayah>>> getBookmarkedAyahs(bool value) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );
  List<Ayah> translationAyahs = isar.ayahs.filter().bookmarkedEqualTo(true).findAllSync();
  List<Ayah> arabicAyahs = [];
  for (Ayah ayah in translationAyahs) {
    Ayah foundAyah = isar.ayahs.filter().languageEqualTo(kArabicText).and().numberEqualTo(ayah.number).findFirstSync()!;

    arabicAyahs.add(foundAyah);
  }
  return [arabicAyahs, translationAyahs];
}

Future<List<dynamic>> getAyahByNumber(int number) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  Ayah translation = isar.ayahs
      .filter()
      .numberEqualTo(number)
      .and()
      .languageEqualTo(isar.textTranslations.filter().isSelectedEqualTo(true).findFirstSync()!.identifier)
      .findFirstSync()!;
  Ayah arabic = isar.ayahs.filter().numberEqualTo(number).and().languageEqualTo(kArabicText).findFirstSync()!;

  Surah surah = isar.surahs.filter().numberEqualTo(arabic.chapterNo).findFirstSync()!;
  return [arabic, translation, surah];
}

Future<List<List<Ayah>>> finAyahsByWord(String query) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  List<Ayah> foundAyahs = isar.ayahs.where().ayahWordsElementEqualTo(query).findAllSync();
  List<Ayah> arabicAyahs = [];
  for (Ayah ayah in foundAyahs) {
    Ayah foundAyah = isar.ayahs.filter().languageEqualTo(kArabicText).and().numberEqualTo(ayah.number).findFirstSync()!;

    arabicAyahs.add(foundAyah);
  }
  return [arabicAyahs, foundAyahs];
}

Future<List<List<Ayah>>> finAyahsBySentence(String query) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  List<Ayah> foundAyahs = isar.ayahs.filter().textContains(query, caseSensitive: false).findAllSync();
  List<Ayah> arabicAyahs = [];
  for (Ayah ayah in foundAyahs) {
    Ayah foundAyah = isar.ayahs.filter().languageEqualTo(kArabicText).and().numberEqualTo(ayah.number).findFirstSync()!;

    arabicAyahs.add(foundAyah);
  }
  return [arabicAyahs, foundAyahs];
}

Future<bool> downloadAyahTranslation(String identifier) async {
  try {
    Response response = await get(Uri.parse('http://api.alquran.cloud/v1/quran/$identifier'));
    if (response.statusCode == 200) {
      await addNewTranslation(response.body);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> addNewTranslation(String translation) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  final translationQuranTextJson = quranTextTranslationFromJson(translation);
  TextTranslation textTranslation = isar.textTranslations
      .filter()
      .identifierEqualTo(translationQuranTextJson!.data.edition.identifier)
      .findFirstSync()!;
  List<Ayah> newEnglishAyahs = [];
  List<SurahTranslation> translationsurahModels = translationQuranTextJson.data.surahs;
  for (SurahTranslation surah in translationsurahModels) {
    List<AyahTranslation> ayahs = surah.ayahs;
    for (AyahTranslation ayah in ayahs) {
      String? sajda;
      if (ayah.sajda.toString() != 'false') {
        if (ayah.sajda['recommended']) {
          sajda = 'Sajda Recommended';
        } else {
          sajda = 'Sajda Obligatory';
        }
      }
      newEnglishAyahs.add(Ayah(
          chapterNo: surah.number,
          language: translationQuranTextJson.data.edition.identifier,
          number: ayah.number,
          text: ayah.text,
          numberInSurah: ayah.numberInSurah,
          juz: ayah.juz,
          manzil: ayah.manzil,
          page: ayah.page,
          ruku: ayah.ruku,
          hizbQuarter: ayah.hizbQuarter,
          sajda: sajda,
          direction: textTranslation.direction));
    }
  }

  isar.writeTxnSync(() {
    isar.ayahs.putAllSync(
      newEnglishAyahs,
    );
  });

  return true;
}

Future<String?> getYearlyPrayerTimings(UserPrayerPreference userData) async {
  try {
    int year = DateTime.now().year;
    Response response = await get(Uri.parse(
        'https://api.aladhan.com/v1/calendarByCity?city=${userData.city}&country=${userData.country}&method=${userData.method}&annual=true&year=$year&iso8601=true&school=${userData.school}'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<String?> getUserIPInfo(bool _) async {
  try {
    Response response = await get(Uri.parse('http://ip-api.com/json'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<bool> updateSurah(Surah surah) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );

  isar.writeTxnSync(() {
    isar.surahs.putSync(surah);
  });
  return true;
}

Future<bool> resetSurahsDurations(bool _) async {
  Isar isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    name: 'main',
    directory: '',
    inspector: false,
  );
  List<Surah> surahs = isar.surahs.where().findAllSync();
  for (Surah surah in surahs) {
    surah.currentDuration = 0;
    surah.totalDuration = 1;
  }
  isar.writeTxnSync(() {
    isar.surahs.putAllSync(surahs);
  });
  return true;
}

Future<int> generatePrayerNotifications(String prayerTimeData) async {
  int currentId = 0;
  YearlyPrayerTiming yearlyPrayerTiming = YearlyPrayerTiming.fromJson(json.decode(prayerTimeData));
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(yearlyPrayerTiming.data.months[0][0].meta.timezone));

  for (Daily daily in yearlyPrayerTiming.data.months[DateTime.now().month - 1]) {
    for (Prayer prayer in daily.timings.prayers) {
      if (prayer.name != AppStrings.imsak &&
          prayer.name != AppStrings.sunrise &&
          prayer.name != AppStrings.sunset &&
          prayer.name != AppStrings.midnight &&
          prayer.name != AppStrings.firstthird &&
          prayer.name != AppStrings.lastthird) {
        currentId = currentId + 1;
        DateTime prayerTime = DateTime.parse(prayer.time).toLocal();
        UC.flutterLocalNotificationsPlugin?.zonedSchedule(
          currentId,
          AppStrings.prayerReminder,
          'It is time for ${prayer.name} prayer.',
          tz.TZDateTime(
              tz.local, prayerTime.year, prayerTime.month, prayerTime.day, prayerTime.hour, prayerTime.minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(AppStrings.quranAppPrayerNotifications, AppStrings.prayerNotifications,
                channelDescription: AppStrings.prayerTimeNotifications,
                styleInformation: BigTextStyleInformation(''),
                importance: Importance.max,
                priority: Priority.high),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
      }
    }
  }
  UC.hive.put(kAdhanNotificationSet, DateTime.now().month);
  return DateTime.now().month;
}

Future initPurchases() async {
  await Purchases.setDebugLogsEnabled(true);
  PurchasesConfiguration(googleApiKey);
}

Future<void> initPlatformState() async {
  await Purchases.setDebugLogsEnabled(true);

  PurchasesConfiguration configuration = PurchasesConfiguration(googleApiKey);
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration(googleApiKey);
  }
  await Purchases.configure(configuration);
}

Future<List<Offering>> fetchOffers() async {
  try {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;

    return current == null ? [] : [current];
  } on PlatformException {
    return [];
  }
}

Future<bool> purchasePackage(Package package, BuildContext context) async {
  try {
    await Purchases.purchasePackage(package).then(
      (value) => Navigator.of(context).pushNamed(HomePre.id),
    );

    return true;
  } catch (e) {
    return false;
  }
}

Future<void> lauchUrl(String url) async {
  if (await canLaunchUrl(
    Uri.parse(
      url,
    ),
  )) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

void showSubscribeScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubscribeScreen(
        isMainPage: true,
        onClickedPackage: (package) async {
          await purchasePackage(package, context);

          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        },
      ),
    ),
  );
}

void showRatingWindow(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    builder: (_) => const LikeAppWidget(),
  );
}

// Показать интер каждый 6 клик
void showInterAtSixTime(BuildContext context) {
  UtilsScreen.counter++;
  
  if (UtilsScreen.counter == 1 && !UtilsScreen.isStarted) {
    UtilsScreen.isStarted = true;
    context.read<InterstitialProvider>().showInterstitialAd();
  } else if (UtilsScreen.counter == 6) {
    context.read<InterstitialProvider>().showInterstitialAd();
    UtilsScreen.counter = 0;
  }
}
