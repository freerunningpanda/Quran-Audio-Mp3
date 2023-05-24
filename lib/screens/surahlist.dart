import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:quran/screens/eachsurahtext.dart';
import 'package:quran/screens/ayahbyayah.dart';
import 'package:flutter/material.dart';
import 'package:quran/widgets/reuseablewidgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/banner_provider.dart';
import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'bookmark.dart';

final surahProvider = riverpod.ChangeNotifierProvider.autoDispose
    .family<SurahController, bool>((_, textSurah) => SurahController(textSurah));

class SurahController with ChangeNotifier {
  TextEditingController textEditingController = TextEditingController();

  FocusNode focusNode = FocusNode();
  bool isSearching = false;
  Surah? lastReadSurah;
  Ayah? lastReadAyah;
  double lastReadPercentage = 0.0;

  updateSearch(bool _) {
    isSearching = _;

    notifyListeners();
  }

  void unfocusClear() {
    focusNode.unfocus();
    textEditingController.clear();
    searchByNameOrNumber('');
  }

  void startupServices() async {
    await generateChaptersList();
    focusNode.unfocus();
  }

  bool textSurah;
  SurahController(this.textSurah) {
    startupServices();
  }

  void chapterSelect({
    required BuildContext context,
    required Surah surah,
  }) async {
    FocusScope.of(context).unfocus();
    textEditingController.clear();
    searchByNameOrNumber('');
    if (textSurah) {
      Ayah? ayah = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (
            context,
          ) =>
              EachQuranText(
            chapterNo: surah.number,
          ),
        ),
      );
      updateLastReadValues(surah, ayah);
    } else {
      Ayah? ayah = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AyahByAyahScreen(
            chapterNo: surah.number,
          ),
        ),
      );
      updateLastReadValues(surah, ayah);
    }
  }

  void bookmarkSurah(Surah surah) {
    surah.bookmarked = !(surah.bookmarked ?? false);
    UC.isar.writeTxnSync(() {
      UC.isar.surahs.putSync(surah);
    });
    notifyListeners();
  }

  List<Surah> totalChapters = <Surah>[];
  List<Surah> foundChapters = <Surah>[];

  int verseByVerse = 0;

  generateChaptersList() async {
    List<Surah> chapters = await compute(getAllSurahs, true);
    totalChapters = chapters;
    foundChapters = chapters;
    await generateLastReadValues();

    notifyListeners();
  }

  generateLastReadValues() async {
    if (textSurah) {
      lastReadSurah = UC.isar.surahs.filter().not().lastReadIsNull().sortByLastReadDesc().findFirstSync();
      lastReadAyah = UC.isar.ayahs
          .filter()
          .group((q) => q.languageEqualTo(kArabicText).and().not().lastReadIsNull())
          .sortByLastReadDesc()
          .findFirstSync();

      if (lastReadAyah != null && lastReadSurah != null) {
        lastReadPercentage = (lastReadAyah!.numberInSurah / lastReadSurah!.numberOfAyahs);
      }
    } else {
      lastReadAyah = UC.isar.ayahs
          .filter()
          .group((q) => q.not().lastReadIsNull()..and().languageEqualTo(kEnglishText))
          .sortByLastReadDesc()
          .findFirstSync();

      if (lastReadAyah != null) {
        lastReadSurah = UC.isar.surahs.filter().numberEqualTo(lastReadAyah!.chapterNo).findFirstSync();
        lastReadPercentage = (lastReadAyah!.numberInSurah / lastReadSurah!.numberOfAyahs);
      }
    }
  }

  updateLastReadValues(Surah? surah, Ayah? ayah) {
    lastReadSurah = surah;
    lastReadAyah = ayah;

    if (lastReadAyah != null && lastReadSurah != null) {
      lastReadPercentage = (lastReadAyah!.numberInSurah / lastReadSurah!.numberOfAyahs);
    }

    notifyListeners();
  }

  searchByNameOrNumber(String str) {
    if (str.isEmpty) {
      foundChapters = totalChapters;
      notifyListeners();
    }
    int value = int.tryParse(str) ?? 0;
    if (value != 0 && value < 115) {
      List<Surah> current = [];
      for (int i = 0; i < totalChapters.length; i++) {
        final toMatch = RegExp('$value');
        if (toMatch.hasMatch(totalChapters[i].number.toString())) {
          current.add(totalChapters[i]);
        }
      }

      foundChapters = current;
      notifyListeners();
    } else {
      List<Surah> current = [];
      for (int i = 0; i < totalChapters.length; i++) {
        String lower = str.toLowerCase();

        final toMatch = RegExp(lower);
        if (toMatch.hasMatch(totalChapters[i].englishName.toLowerCase())) {
          current.add(totalChapters[i]);
        }
      }

      foundChapters = current;
      notifyListeners();
    }
  }
}

class QuranFull extends riverpod.ConsumerWidget {
  static const id = 'QuranFull';
  final bool textSurah;
  const QuranFull({Key? key, this.textSurah = true}) : super(key: key);

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final sP = ref.watch(surahProvider(textSurah));
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        sP.isSearching ? sP.updateSearch(false) : null;
        return true;
      },
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: theme.canvasColor,
            appBar: AppBar(
              backgroundColor: theme.canvasColor,
              title: sP.isSearching
                  ? Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 3.0),
                      height: 45.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: CupertinoSearchTextField(
                              autofocus: true,
                              focusNode: sP.focusNode,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15.0,
                              ),
                              controller: sP.textEditingController,
                              onChanged: (String str) {
                                sP.searchByNameOrNumber(str);
                              },
                              onSubmitted: (String str) {
                                sP.searchByNameOrNumber(str);
                              },
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context)!.searchSurahs,
                    ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                  child: InkWell(
                    onTap: () {
                      sP.updateSearch(true);
                    },
                    child: const Icon(
                      CupertinoIcons.search,
                      size: 20.0,
                    ),
                  ),
                ),
              ],
              elevation: 0,
              bottom: const _TabBarWidget(),
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: TabBarView(
                children: [
                  Scrollbar(
                    radius: const Radius.circular(
                      10.0,
                    ),
                    thickness: 15.0,
                    interactive: true,
                    child: AnimationLimiter(
                      child: ListView(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            itemExtent: 100,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sP.foundChapters.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              if (sP.foundChapters.isEmpty == false) {
                                return AnimationConfiguration.staggeredGrid(
                                  columnCount: sP.foundChapters.length,
                                  position: index,
                                  duration: const Duration(milliseconds: 475),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: FutureBuilder(
                                          future: context.read<RevenueCatProvider>().getSubs(),
                                          builder: (_, snapshot) {
                                            final bannerAd = context.read<BannerProvider>().bannerAd;
                                            final isAdLoad = context.read<InterstitialProvider>().isAdLoad;
                                            final bannerAdIsLoaded = context.read<BannerProvider>().bannerAdIsLoaded;
                                            final adManagerBannerAdIsLoaded =
                                                context.read<BannerProvider>().adManagerBannerAdIsLoaded;
                                            if (snapshot.hasData &&
                                                snapshot.data == false &&
                                                bannerAd != null &&
                                                isAdLoad &&
                                                bannerAdIsLoaded &&
                                                adManagerBannerAdIsLoaded) {
                                              return EachTextSurahWidget(
                                                chapterNo: sP.foundChapters[index].number.toString(),
                                                chapterNameEn: sP.foundChapters[index].englishName,
                                                chapterNameAr: sP.foundChapters[index].name,
                                                chapterNametranslation: sP.foundChapters[index].englishNameTranslation,
                                                chapterType: sP.foundChapters[index].revelationType,
                                                chapterAyats: sP.foundChapters[index].numberOfAyahs.toString(),
                                                isFavourite: sP.foundChapters[index].bookmarked ?? false,
                                                tap: () async {
                                                  showInterAtSixTime(context);
                                                  sP.chapterSelect(
                                                    context: context,
                                                    surah: sP.foundChapters[index],
                                                  );
                                                },
                                                likeButton: () {
                                                  sP.bookmarkSurah(sP.foundChapters[index]);
                                                },
                                              );
                                            }
                                            return EachTextSurahWidget(
                                              chapterNo: sP.foundChapters[index].number.toString(),
                                              chapterNameEn: sP.foundChapters[index].englishName,
                                              chapterNameAr: sP.foundChapters[index].name,
                                              chapterNametranslation: sP.foundChapters[index].englishNameTranslation,
                                              chapterType: sP.foundChapters[index].revelationType,
                                              chapterAyats: sP.foundChapters[index].numberOfAyahs.toString(),
                                              isFavourite: sP.foundChapters[index].bookmarked ?? false,
                                              tap: () async {
                                                sP.chapterSelect(
                                                  context: context,
                                                  surah: sP.foundChapters[index],
                                                );
                                              },
                                              likeButton: () {
                                                sP.bookmarkSurah(sP.foundChapters[index]);
                                              },
                                            );
                                          }),
                                    ),
                                  ),
                                );
                              } else {
                                return SizedBox(
                                  width: 2000.0,
                                  height: 100.0,
                                  child: Text(
                                    AppLocalizations.of(context)!.loading,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 40.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  BookmarkScreen(isTranslationPage: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarWidget extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  const _TabBarWidget({Key? key}) : super(key: key);

  @override
  State<_TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<_TabBarWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        indicatorColor: theme.primaryColor,
        tabs: [
          Tab(
            child: Text(
              AppLocalizations.of(context)!.surahs,
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.2,
              ),
            ),
          ),
          Tab(
            child: Text(
              AppLocalizations.of(context)!.bookMarks,
              style: theme.textTheme.titleLarge?.copyWith(
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
