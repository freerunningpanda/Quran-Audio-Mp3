// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:isar/isar.dart';
import 'package:quran/provider/banner_provider.dart';
import 'package:quran/provider/interstitial_provider.dart';
import 'package:quran/screens/fake_startup_screen.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/audiostate.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart' as provider;

import 'package:quran/main.dart';
import 'package:quran/data/models/yearlyprayertiming.dart';
import 'package:quran/screens/audioquran.dart';
import 'package:quran/screens/bookmark.dart';
import 'package:quran/screens/surahlist.dart';
import 'package:quran/screens/settings.dart';
import 'package:quran/utils/rate_app_preferences.dart';
import 'package:quran/widgets/customanimations.dart';

import '../data/explore_tab.dart';
import '../provider/revenue_cat_provider.dart';
import '../widgets/appbar_widget.dart';
import '../widgets/decoration_border_widget.dart';
import '../widgets/like_app_widget.dart';
import '../widgets/quran_icons.dart';
import 'prayer_times.dart';
import 'recently_listen_surahs.dart';
import 'recently_read_surahs.dart';
import 'res/app_assets.dart';
import 'res/app_colors.dart';

final homeProvider = ChangeNotifierProvider((_) => HomeController());

class HomeController with ChangeNotifier {
  Ayah? todayAyah;
  Ayah? todayAyahTranslation;
  Surah? todaySurah;
  late Surah todayChapter;
  late final Daily todayCalender;
  late Prayer currentPrayer;
  late Prayer nextPrayer;
  late final String cityName;

  List<Ayah> lastReadTextAyahs = [];
  List<Surah> lastReadTextSurahs = [];
  List<Surah> lastRecitedSurahs = [];

  refresh(Surah surah) {
    lastRecitedSurahs.remove(surah);
    lastRecitedSurahs.insert(0, surah);
    notifyListeners();
  }

  HomeController() {
    generateTodayPrayers();
    currentPrayerAndNext();
    genereRandomAyah();
    generateLastReadValues();
  }

  bool isRecitingAyah = false;
  reciteAyah({required BuildContext context, required WidgetRef ref, required Ayah ayah}) async {
    isRecitingAyah = true;
    notifyListeners();
    final snackBar = SnackBar(
      content: AyahRecitingWidget(
        text: ayah.text,
        textDirection: ayah.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      ),
      duration: const Duration(minutes: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    Duration? duration = await ref.read(audioStateProvider).reciteAyah(ayah: ayah);
    if (duration != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final snackBar = SnackBar(
        content: AyahRecitingWidget(
          duration: duration,
          text: ayah.text,
          textDirection: ayah.direction == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
        ),
        duration: duration,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    isRecitingAyah = false;
    notifyListeners();
  }

  currentPrayerAndNext() {
    DateTime now = DateTime.now();

    for (Prayer prayer in todayCalender.timings.prayers) {
      DateTime prayerTime = DateTime.parse(prayer.time).toLocal();

      if (prayerTime.compareTo(now) == -1) {
        currentPrayer = prayer;
      } else {
        nextPrayer = prayer;
        break;
      }
    }
    notifyListeners();
  }

  generateTodayPrayers() {
    YearlyPrayerTiming yearlyPrayerTiming = YearlyPrayerTiming.fromJson(
      jsonDecode(
        UC.hive.get(kYearlyPrayerTimings),
      ),
    );
    UserPrayerPreference userPrayerPreference =
        UserPrayerPreference.fromJson(json.decode(UC.hive.get(kUserPrayerPrefencees)));
    cityName = userPrayerPreference.city;
    todayCalender = yearlyPrayerTiming.data.months[DateTime.now().month - 1][DateTime.now().day - 1];
    todayCalender.timings.prayers.sort(((a, b) => a.time.compareTo(b.time)));
    Prayer lastThird = todayCalender.timings.prayers.first;
    todayCalender.timings.prayers.removeAt(0);
    todayCalender.timings.prayers.add(lastThird);
    notifyListeners();
  }

  void bookmarkAyah() {
    todayAyahTranslation!.bookmarked = !(todayAyahTranslation!.bookmarked ?? false);
    UC.isar.writeTxnSync(() {
      UC.isar.ayahs.putSync(todayAyahTranslation!);
    });
    notifyListeners();
  }

  generateLastReadValues() async {
    lastReadTextSurahs = UC.isar.surahs.filter().lastReadIsNotNull().sortByLastReadDesc().findAllSync();

    lastReadTextAyahs = UC.isar.ayahs
        .filter()
        .lastReadIsNotNull()
        .and()
        .languageEqualTo(kArabicText)
        .sortByLastReadDesc()
        .findAllSync();
    lastRecitedSurahs = await compute(getLastRecitedSurahs, true);

    notifyListeners();
  }

  genereRandomAyah() async {
    List response = await compute(getRandomAyah, true);
    todayAyah = response[0];
    todayAyahTranslation = response[1];
    todaySurah = response[2];

    notifyListeners();
  }
}

class HomePre extends StatefulWidget {
  static const String id = "homePre";
  const HomePre({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePre> createState() => _HomePreState();
}

class _HomePreState extends State<HomePre> with WidgetsBindingObserver {
  @override
  void initState() {
    context.read<RevenueCatProvider>().fetchOffer(context);
    bool storeVisited = RateAppPreferences.getStoreVisitValue();
    bool isFirstTime = RateAppPreferences.getFirstTimeLaunchValue();

    debugPrint('isFirstTime initial value: $isFirstTime');
    // Если приложение запущено в первый раз
    if (isFirstTime) {
      // Меняем флаг isFirstOpening на false через 10 секунд, чтобы не вызвало showRatingWindow
      // поверх экрана подписки
      Future.delayed(
        const Duration(seconds: 10),
        () => RateAppPreferences.setFirstTimeAppLaunch(isFirstOpening = false),
      );
      if (!storeVisited) {
        // Здесь мы показываем окно оценки через 1 день
        Future.delayed(
          const Duration(days: 1),
          () => showRatingWindow(context),
        );
        debugPrint('isFirstTime value: $isFirstTime');
      }
    } else {
      // Если приложение запущено не первый раз
      // Юзер увидит экран подписки
      Future.delayed(
        const Duration(seconds: 6),
        () => showSubscribeScreen(context),
      );
    }

    super.initState();
    initBanner();
    WidgetsBinding.instance.addObserver(this);
  }

  Future initBanner() async {
    await context.read<BannerProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    context.read<RevenueCatProvider>().init();

    context.watch<BannerProvider>();
    context.watch<RevenueCatProvider>();
    return Home();
  }

  @override
  void dispose() {
    super.dispose();
    context.read<BannerProvider>().disposeBanners();
    context.read<InterstitialProvider>().disposeInterstitial();
    WidgetsBinding.instance.removeObserver(this);
  }

  // Запустится при разворачивании приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isSubActive = context.read<RevenueCatProvider>().isSubActive;

    // Если приложение было свёрнуто и подписка не оформлена
    // То будет переход на FakeStartupScreen
    if (state == AppLifecycleState.paused && isSubActive == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, FakeStartupScreen.id);
      });

      debugPrint('Resumed');
    }
  }
}

class Home extends ConsumerWidget {
  static const String id = "home";
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final c = ref.watch(ControllerProvider.controllerProvider);
    final hP = ref.watch(homeProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        appBar: AppBarWidget(c: c),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(
                          AppAssets.readQuran,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      color: theme.cardColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.readAndListenQuran,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headline6?.copyWith(
                              color: theme.selectedRowColor,
                            ),
                          ),
                          FutureBuilder(
                            future: context.read<RevenueCatProvider>().getSubs(),
                            builder: (_, snapshot) {
                              final isAdLoad = context.read<InterstitialProvider>().isAdLoad;
                              final bannerAdIsLoaded = context.read<BannerProvider>().bannerAdIsLoaded;
                              final adManagerBannerAdIsLoaded =
                                  context.read<BannerProvider>().adManagerBannerAdIsLoaded;
                              if (snapshot.hasData &&
                                  snapshot.data == false &&
                                  isAdLoad &&
                                  bannerAdIsLoaded &&
                                  adManagerBannerAdIsLoaded) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    hP.lastRecitedSurahs.isEmpty
                                        ? Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.cardColor,
                                              textColor: theme.secondaryHeaderColor,
                                              title: AppLocalizations.of(context)!.listenQuran,
                                              onTap: () {
                                                showInterAtSixTime(context);
                                                Navigator.pushNamed(context, QuranAudio.id);
                                              },
                                            ),
                                          )
                                        : Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.primaryColor,
                                              textColor: AppColors.white,
                                              title: AppLocalizations.of(context)!.continueListening,
                                              onTap: () {
                                                showInterAtSixTime(context);
                                                Navigator.pushNamed(context, RecentlyListenSurahs.id);
                                              },
                                            ),
                                          ),
                                    const SizedBox(width: 10),
                                    hP.lastReadTextAyahs.isEmpty
                                        ? Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.cardColor,
                                              textColor: theme.secondaryHeaderColor,
                                              title: AppLocalizations.of(context)!.readQuran,
                                              onTap: () {
                                                showInterAtSixTime(context);
                                                Navigator.pushNamed(context, QuranFull.id);
                                              },
                                            ),
                                          )
                                        : Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.primaryColor,
                                              textColor: AppColors.white,
                                              title: AppLocalizations.of(context)!.continueReading,
                                              onTap: () {
                                                showInterAtSixTime(context);
                                                Navigator.pushNamed(context, RecentlyReadSurahs.id);
                                              },
                                            ),
                                          ),
                                  ],
                                );
                              } else {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    hP.lastRecitedSurahs.isEmpty
                                        ? Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.cardColor,
                                              textColor: theme.secondaryHeaderColor,
                                              title: AppLocalizations.of(context)!.listenQuran,
                                              onTap: () => Navigator.pushNamed(context, QuranAudio.id),
                                            ),
                                          )
                                        : Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.primaryColor,
                                              textColor: AppColors.white,
                                              title: AppLocalizations.of(context)!.continueListening,
                                              onTap: () => Navigator.pushNamed(context, RecentlyListenSurahs.id),
                                            ),
                                          ),
                                    const SizedBox(width: 10),
                                    hP.lastReadTextAyahs.isEmpty
                                        ? Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.cardColor,
                                              textColor: theme.secondaryHeaderColor,
                                              title: AppLocalizations.of(context)!.readQuran,
                                              onTap: () => Navigator.pushNamed(context, QuranFull.id),
                                            ),
                                          )
                                        : Flexible(
                                            child: ActionButton(
                                              buttonColor: theme.primaryColor,
                                              textColor: AppColors.white,
                                              title: AppLocalizations.of(context)!.continueReading,
                                              onTap: () => Navigator.pushNamed(context, RecentlyReadSurahs.id),
                                            ),
                                          ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 0.5,
                          blurStyle: BlurStyle.normal,
                          color: theme.shadowColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Wrap(
                      runSpacing: 10,
                      spacing: 16,
                      children: ExploreTab.exploreItems
                          .map((e) => EachExploreTab(
                                index: e.index,
                                assetName: e.assetName,
                              ))
                          .toList(),
                    ),
                  ],
                ),
                FutureBuilder(
                  future: context.read<RevenueCatProvider>().getSubs(),
                  builder: (_, snapshot) {
                    final bannerAd = context.read<BannerProvider>().bannerAd;
                    final isAdLoad = context.read<InterstitialProvider>().isAdLoad;
                    final bannerAdIsLoaded = context.read<BannerProvider>().bannerAdIsLoaded;
                    final adManagerBannerAdIsLoaded = context.read<BannerProvider>().adManagerBannerAdIsLoaded;
                    if (snapshot.hasData &&
                        snapshot.data == false &&
                        bannerAd != null &&
                        isAdLoad &&
                        bannerAdIsLoaded &&
                        adManagerBannerAdIsLoaded) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            height: bannerAd.size.height.toDouble(),
                            width: bannerAd.size.width.toDouble(),
                            child: AdWidget(
                              ad: bannerAd,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final Color? textColor;
  final Color buttonColor;
  final String title;
  final VoidCallback onTap;
  final double? size;
  const ActionButton({
    Key? key,
    required this.title,
    required this.onTap,
    required this.textColor,
    required this.buttonColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Stack(
        children: [
          Container(
            height: 40,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: buttonColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EachExploreTab extends ConsumerWidget {
  final String assetName;
  final int index;

  const EachExploreTab({
    Key? key,
    required this.index,
    required this.assetName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Stack(
        children: [
          DecorationBorderWidget(
            width: MediaQuery.of(context).size.width / 2.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuranIcons(
                    assetName: assetName,
                    width: 24,
                    height: 24,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (index == 0)
                        Text(
                          AppLocalizations.of(context)!.fullQuran,
                          style: theme.textTheme.bodyLarge,
                        )
                      else if (index == 1)
                        Text(
                          AppLocalizations.of(context)!.audioQuran,
                          style: theme.textTheme.bodyLarge,
                        )
                      else if (index == 2)
                        Text(
                          AppLocalizations.of(context)!.prayerTimes,
                          style: theme.textTheme.bodyLarge,
                        )
                      else if (index == 3)
                        Text(
                          AppLocalizations.of(context)!.quranTranslation,
                          style: theme.textTheme.bodyLarge,
                        )
                      else if (index == 4)
                        Text(
                          AppLocalizations.of(context)!.bookMarks,
                          style: theme.textTheme.bodyLarge,
                        )
                      else if (index == 5)
                        Text(
                          AppLocalizations.of(context)!.settings,
                          style: theme.textTheme.bodyLarge,
                        )
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                return Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () async {
                        switch (index) {
                          case 0:
                            showInterAtSixTime(context);
                            await Navigator.pushNamed(context, QuranFull.id);
                            break;
                          case 1:
                            showInterAtSixTime(context);
                            await Navigator.pushNamed(context, QuranAudio.id);
                            break;
                          case 2:
                            showInterAtSixTime(context);
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return PrayerList();
                                },
                              ),
                            );
                            break;
                          case 3:
                            showInterAtSixTime(context);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranFull(
                                  textSurah: false,
                                ),
                              ),
                            );

                            break;
                          case 4:
                            showInterAtSixTime(context);
                            await Navigator.pushNamed(context, BookmarkScreen.id);
                            break;
                          case 5:
                            showInterAtSixTime(context);
                            await Navigator.pushNamed(context, SettingsScreen.id);
                            break;
                          default:
                            break;
                        }
                        ref.read(homeProvider).generateLastReadValues();
                      },
                    ),
                  ),
                );
              } else {
                return Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () async {
                        switch (index) {
                          case 0:
                            await Navigator.pushNamed(context, QuranFull.id);
                            break;
                          case 1:
                            await Navigator.pushNamed(context, QuranAudio.id);
                            break;
                          case 2:
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return PrayerList();
                                },
                              ),
                            );
                            break;
                          case 3:
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranFull(
                                  textSurah: false,
                                ),
                              ),
                            );

                            break;
                          case 4:
                            await Navigator.pushNamed(context, BookmarkScreen.id);
                            break;
                          case 5:
                            await Navigator.pushNamed(context, SettingsScreen.id);
                            break;
                          default:
                            break;
                        }
                        ref.read(homeProvider).generateLastReadValues();
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
