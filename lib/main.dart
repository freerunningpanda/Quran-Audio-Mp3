import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:quran/utils/constants.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/audiostate.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/utils/initialization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:quran/screens/audioquran.dart';
import 'package:quran/screens/bookmark.dart';
import 'package:quran/screens/prayersettings.dart';
import 'package:quran/screens/startup.dart';
import 'package:quran/screens/surahlist.dart';
import 'package:quran/screens/home.dart';
import 'package:quran/screens/reciters.dart';
import 'package:quran/screens/settings.dart';
import 'package:quran/screens/audiotranslations.dart';
import 'package:quran/screens/texttranslations.dart';
import 'package:provider/provider.dart' as provider;
import 'package:package_info_plus/package_info_plus.dart';

import 'provider/banner_provider.dart';
import 'provider/firebase_analytics_provider.dart';
import 'provider/interstitial_provider.dart';
import 'provider/revenue_cat_provider.dart';
import 'screens/fake_startup_screen.dart';
import 'screens/font_size_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recently_listen_surahs.dart';
import 'screens/recently_read_surahs.dart';
import 'screens/res/app_colors.dart';
import 'screens/res/app_strings.dart';
import 'screens/subscribe_screen.dart';
import 'utils/rate_app_preferences.dart';

class UC {
  static late Box hive;
  static late Isar isar;
  static late ImageProvider quranjpg;
  static late UniversalVariables uv;
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
}

class ControllerProvider {
  static final controllerProvider = riverpod.ChangeNotifierProvider((_) => Controller());
}

class Controller with ChangeNotifier {
  int appThemeMode = UC.hive.get(kAppThemeMode, defaultValue: 0);
  int initializedVersion = UC.hive.get(kInitializedVersion, defaultValue: 2);

  void updateAppTheme(int value) {
    appThemeMode = value;

    UC.hive.put(kAppThemeMode, value);
    notifyListeners();
  }
}

class UniversalVariables with ChangeNotifier {
  UniversalVariables() {
    initializeClass();
  }
  Reciter selectedReciter = UC.isar.reciters.filter().isSelectedEqualTo(true).findFirstSync()!;

  updateSelectedReciter(Reciter newSelectedReciter) {
    selectedReciter = newSelectedReciter;
  }

  TextTranslation selectedTextTranslation = UC.isar.textTranslations.filter().isSelectedEqualTo(true).findFirstSync()!;

  updateSelectedTextTranslation(TextTranslation newSelectedTextTranslation) {
    selectedTextTranslation = newSelectedTextTranslation;
  }

  String selectedAudioTranslation =
      UC.hive.get(kSelectedAudioTranslation, defaultValue: kDefaultSelectedAudioTranslation);

  updateSelectedAudioTranslation(String newSelectedAudioTranslation) {
    selectedAudioTranslation = newSelectedAudioTranslation;
    UC.hive.put(kSelectedAudioTranslation, newSelectedAudioTranslation);
  }

  double selectedArabicFontSize = UC.hive.get(kSelectedArabicFontSize, defaultValue: kDefaultArabicSelectedFontSize);

  updateSelectedArabicFontSize(double newSelectedFontSize) {
    selectedArabicFontSize = newSelectedFontSize;
    UC.hive.put(kSelectedArabicFontSize, newSelectedFontSize);
  }

  double selectedTranslationFontSize =
      UC.hive.get(kSelectedTranslationFontSize, defaultValue: kDefaultTranslationSelectedFontSize);

  updateSelectedTranslationFontSize(double newSelectedFontSize) {
    selectedTranslationFontSize = newSelectedFontSize;
    UC.hive.put(kSelectedTranslationFontSize, newSelectedFontSize);
  }

  AudioType selectedAudioType =
      UC.hive.get(kSelectedAudioType, defaultValue: kDefaultAudioType.toString()) == AudioType.arabic.toString()
          ? kDefaultAudioType
          : AudioType.translation;
  late final Directory appDirectory;
  late final String appDirectoryPath;
  initializeClass() async {
    appDirectory = await getApplicationDocumentsDirectory();
    appDirectoryPath = appDirectory.path;
  }

  updateSelectedAudioType(AudioType newSelectedAudioType) {
    selectedAudioType = newSelectedAudioType;
    UC.hive.put(kSelectedAudioType, newSelectedAudioType.toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
  await Hive.initFlutter();
  await RateAppPreferences.init();
  await initPlatformState();
  await PackageInfo.fromPlatform();

  UC.hive = await Hive.openBox(kHiveBox);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.simpleapp.quranapp.channel.audio',
    androidNotificationChannelName: 'Recitation',
    androidNotificationOngoing: true,
    notificationColor: const Color(0XFF29BB89),
  );
  UC.flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await UC.flutterLocalNotificationsPlugin?.initialize(
    initializationSettings,
  );
  final dir = await getApplicationSupportDirectory();
  UC.isar = await Isar.open(
    [AyahSchema, SurahSchema, ReciterSchema, TextTranslationSchema],
    directory: dir.path,
    name: 'main',
    inspector: false,
  );

  await Initialization.checkPrayers();
  if (UC.hive.get(kInitializedVersion) != null) {
    UC.uv = UniversalVariables();
  }
  runApp(
    riverpod.ProviderScope(
      child: provider.ListenableProvider(
        create: (context) => RevenueCatProvider(),
        child: provider.ListenableProvider(
          create: (context) => BannerProvider()
            ..init()
            ..initManagerBanner(),
          child: provider.ListenableProvider(
            create: (context) => InterstitialProvider()..createInterstitialAd(),
            child: provider.ListenableProvider(create: (context) => FirebaseAnalyticsProvider(), child: const Quran()),
          ),
        ),
      ),
    ),
  );
}

const String testDevice = 'YOUR_DEVICE_ID';
const int maxFailedLoadAttempts = 3;

class Quran extends riverpod.ConsumerWidget {
  const Quran({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final controller = ref.watch(ControllerProvider.controllerProvider);
    final observer = FirebaseAnalyticsProvider.observer;
    context.watch<RevenueCatProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.quranApp,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ru', ''), // Russian, no country code
        Locale('ar', ''), // Arabic, no country code
        Locale('de', ''), // Deutsch, no country code
        Locale('es', ''), // Spainsh, no country code
        Locale('fr', ''), // French, no country code
        Locale('pt', ''), // Portuguese, no country code
        Locale('zh', ''), // Chinese, no country code
      ],
      themeMode: controller.appThemeMode == 0
          ? ThemeMode.system
          : controller.appThemeMode == 1
              ? ThemeMode.light
              : ThemeMode.dark,
      theme: ThemeData.light().copyWith(
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
        focusColor: AppColors.darkGreen,
        primaryColorLight: AppColors.darkGrey,
        secondaryHeaderColor: AppColors.green,
        primaryColor: AppColors.green,
        useMaterial3: true,
        canvasColor: AppColors.scaffoldBackgroundColor,
        cardColor: AppColors.white,
        shadowColor: AppColors.grey,
        selectedRowColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.green, size: 20.0),
        textTheme: const TextTheme(
          displayLarge: kCommonTextStyle,
          displayMedium: kCommonTextStyle,
          displaySmall: kCommonTextStyle,
          headlineLarge: kCommonTextStyle,
          headlineMedium: kCommonTextStyle,
          headlineSmall: kCommonTextStyle,
          titleLarge: kCommonTextStyle,
          titleMedium: kCommonTextStyle,
          titleSmall: kCommonTextStyle,
          bodyLarge: kCommonTextStyle,
          bodyMedium: kCommonTextStyle,
          bodySmall: kCommonTextStyle,
          labelLarge: kCommonTextStyle,
          labelMedium: kCommonTextStyle,
          labelSmall: kCommonTextStyle,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          color: AppColors.green,
          elevation: 0.0,
          surfaceTintColor: AppColors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            surfaceTintColor: MaterialStateProperty.all(AppColors.green),
            shape: MaterialStateProperty.resolveWith<RoundedRectangleBorder>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                );
              } else if (states.contains(MaterialState.hovered)) {
                return const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              );
            }),
            elevation: MaterialStateProperty.resolveWith<double>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 0.0;
              return 5.0;
            }),
          ),
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
        sliderTheme: const SliderThemeData(
            overlayColor: AppColors.greenWithOpacity,
            thumbColor: AppColors.green,
            activeTrackColor: AppColors.green,
            inactiveTrackColor: AppColors.greenWithOpacity),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColorLight: AppColors.grey,
        secondaryHeaderColor: AppColors.white,
        primaryColor: AppColors.green,
        useMaterial3: true,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        selectedRowColor: AppColors.green,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            surfaceTintColor: MaterialStateProperty.all(AppColors.white),
            shape: MaterialStateProperty.resolveWith<RoundedRectangleBorder>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                );
              } else if (states.contains(MaterialState.hovered)) {
                return const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              );
            }),
            foregroundColor: MaterialStateProperty.all(
              Theme.of(context).canvasColor,
            ),
            backgroundColor: MaterialStateProperty.all(
              AppColors.grey[850],
            ),
            elevation: MaterialStateProperty.resolveWith<double>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 0.0;
              return 10.0;
            }),
          ),
        ),
        sliderTheme: const SliderThemeData(
            overlayColor: AppColors.greenWithOpacity,
            thumbColor: AppColors.green,
            activeTrackColor: AppColors.green,
            inactiveTrackColor: AppColors.greenWithOpacity),
        textTheme: const TextTheme(
          displayLarge: kCommonTextStyleDark,
          displayMedium: kCommonTextStyleDark,
          displaySmall: kCommonTextStyleDark,
          headlineLarge: kCommonTextStyleDark,
          headlineMedium: kCommonTextStyleDark,
          headlineSmall: kCommonTextStyleDark,
          titleLarge: kCommonTextStyleDark,
          titleMedium: kCommonTextStyleDark,
          titleSmall: kCommonTextStyleDark,
          bodyLarge: kCommonTextStyleDark,
          bodyMedium: kCommonTextStyleDark,
          bodySmall: kCommonTextStyleDark,
          labelLarge: kCommonTextStyleDark,
          labelMedium: kCommonTextStyleDark,
          labelSmall: kCommonTextStyleDark,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          color: Theme.of(context).primaryColor,
        ),
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home:
          // const OnboardingScreen(),
          FutureBuilder(
        future: context.read<RevenueCatProvider>().getSubs(),
        builder: (_, snapshot) {
          if (snapshot.hasData && snapshot.data == false) {
            // Если подписка не оформлена, попадаем на StartupScreen при первом запуске
            // При последующих запусках будет открываться FakeStartupScreen
            if (controller.initializedVersion == kCurrentVersion) {
              return const FakeStartupScreen();
            } else {
              return const StartupScreen();
            }
          } else {
            // Если подписка оформлена, при первом запуске откроется StartupScreen
            // При последующих HomePre
            if (controller.initializedVersion == kCurrentVersion) {
              return const HomePre();
            } else {
              return const StartupScreen();
            }
          }
        },
      ),
      routes: {
        FakeStartupScreen.id: (context) => const FakeStartupScreen(),
        HomePre.id: (context) => const HomePre(),
        QuranFull.id: (context) => const QuranFull(),
        BookmarkScreen.id: (context) => BookmarkScreen(isTranslationPage: false),
        AudioTranslationsScreen.id: (context) => AudioTranslationsScreen(),
        RecitersScreen.id: (context) => RecitersScreen(),
        RecentlyListenSurahs.id: (context) => RecentlyListenSurahs(),
        RecentlyReadSurahs.id: (context) => RecentlyReadSurahs(),
        QuranAudio.id: (context) => QuranAudio(),
        AyahTranslationsScreen.id: (context) => AyahTranslationsScreen(),
        SettingsScreen.id: (context) => const SettingsScreen(),
        PrayerSettingScreen.id: (context) => PrayerSettingScreen(),
        FontSizeScreen.id: (context) => const FontSizeScreen(),
        StartupScreen.id: (context) => const StartupScreen(),
        OnboardingScreen.id: (context) => const OnboardingScreen(),
        SubscribeScreen.id: (context) => SubscribeScreen(
              onClickedPackage: (package) async {
                await purchasePackage(package, context);

                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
      },
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  const BottomNavigation({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: (value) {
        switch (value) {
          case 0:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (c, a1, a2) => const Home(),
                transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 1000),
              ),
            );

            break;
          case 1:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (c, a1, a2) => BookmarkScreen(isTranslationPage: false),
                transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 1000),
              ),
            );

            break;
          default:
        }
      },
      elevation: 20,
      backgroundColor: Theme.of(context).primaryColor,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
          ),
          activeIcon: Icon(Icons.home_filled, color: AppColors.white),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.heart),
          activeIcon: Icon(CupertinoIcons.heart_fill, color: AppColors.white),
          label: '',
        ),
      ],
    );
  }
}
