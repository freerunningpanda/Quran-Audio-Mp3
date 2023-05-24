// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/audiostate.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:quran/screens/eachsurahtext.dart';
import 'package:quran/screens/statusmaker.dart';
import 'package:quran/screens/ayahbyayah.dart';
import 'package:flutter/material.dart';
import 'package:quran/widgets/customanimations.dart';
import 'package:quran/widgets/reuseablewidgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'res/app_strings.dart';

final bookmarkProvider = riverpod.ChangeNotifierProvider.autoDispose((_) => BookmarkController());

class BookmarkController with ChangeNotifier {

  List<Surah> surahs = [];
  List<Ayah> arabicAyahs = [];
  List<Ayah> translationAyahs = [];
  List<Reciter> reciters = [];
  List<TextTranslation> textTranslations = [];
  initialize() async {
    surahs = await compute(getBookmarkedSurahs, true);
    reciters = await compute(getBookmarkedReciters, true);
    textTranslations = await compute(getBookmarkedTextTranslations, true);

    List<List<Ayah>> response = await compute(getBookmarkedAyahs, true);
    arabicAyahs = response[0];

    translationAyahs = response[1];
    currentItemCount = arabicAyahs.length;
    notifyListeners();
  }

  BookmarkController() {
    initialize();
  }

  updateBookmarkReciter(Reciter reciter) {
    reciters.remove(reciter);
    currentItemCount = currentItemCount - 1;
    notifyListeners();
    reciter.bookmarked = !(reciter.bookmarked);
    UC.isar.writeTxn(() {
      return UC.isar.reciters.put(reciter);
    });
  }

  updateSelectedReciter(Reciter reciter) {
    Reciter? alreadySelectedReciter;

    for (Reciter reciter in reciters) {
      if (reciter.isSelected) {
        alreadySelectedReciter = reciter;
        alreadySelectedReciter.isSelected = false;
      }
    }

    reciter.isSelected = true;
    UC.uv.updateSelectedReciter(reciter);
    UC.isar.writeTxn(() {
      return UC.isar.reciters.putAll([reciter, alreadySelectedReciter!]);
    });
    notifyListeners();
    compute(resetSurahsDurations, true);
  }

  updateBookmarkTranslation(TextTranslation textTranslation) {
    textTranslations.remove(textTranslation);
    currentItemCount = currentItemCount - 1;
    notifyListeners();
    textTranslation.bookmarked = !(textTranslation.bookmarked);
    UC.isar.writeTxn(() {
      return UC.isar.textTranslations.put(textTranslation);
    });
  }

  Future<bool> downloadTextTranslation(TextTranslation textTranslation, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading.... It Will take few seconds and only 2mb only the first time'),
        ),
      );
      bool downloaded = await compute(downloadAyahTranslation, textTranslation.identifier);
      if (downloaded == false) return false;

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong.\nYou must have internet connection. It will use only 2mb.'),
          backgroundColor: Colors.red.withOpacity(0.5),
        ),
      );
      return false;
    }
  }

  String currentDownloading = '';
  updateSelectedTextTranslation(TextTranslation textTranslation, BuildContext context) async {
    if (textTranslation.isDownloaded == false) {
      currentDownloading = textTranslation.identifier;
      notifyListeners();
      bool downloaded = await downloadTextTranslation(textTranslation, context);
      if (downloaded == false) return false;
      textTranslation.isDownloaded = true;
    }

    TextTranslation? alreadySelectedTranslation;

    for (TextTranslation tTranslation in textTranslations) {
      if (tTranslation.isSelected) {
        alreadySelectedTranslation = tTranslation;
        alreadySelectedTranslation.isSelected = false;
      }
    }

    textTranslation.isSelected = true;
    UC.isar.writeTxn(() {
      return UC.isar.textTranslations.putAll([textTranslation, alreadySelectedTranslation!]);
    });
    currentDownloading = '';
    notifyListeners();
  }

  bool textSurah = true;
  void chapterSelect({
    required BuildContext context,
    required Surah surah,
  }) async {
    FocusScope.of(context).unfocus();

    if (textSurah) {
      await Navigator.push(
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
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AyahByAyahScreen(
            chapterNo: surah.number,
          ),
        ),
      );

    }
  }

  void updateBookmarkSurah(Surah surah) {
    surahs.remove(surah);
    currentItemCount = currentItemCount - 1;
    notifyListeners();
    surah.bookmarked = !(surah.bookmarked ?? false);
    UC.isar.writeTxnSync(() {
      UC.isar.surahs.putSync(surah);
    });
  }

  void updateBookmarkAyah({required Ayah arabicAyah, required Ayah translationAyah}) {
    arabicAyahs.remove(arabicAyah);
    translationAyahs.remove(translationAyah);
    currentItemCount = currentItemCount - 1;
    notifyListeners();
    translationAyah.bookmarked = !(translationAyah.bookmarked ?? false);
    UC.isar.writeTxnSync(() {
      UC.isar.ayahs.putSync(translationAyah);
    });
  }

  int currentRecitingAyah = 0;
  reciteAyah({required BuildContext context, required riverpod.WidgetRef ref, required Ayah ayah}) async {
    currentRecitingAyah = ayah.number;
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
  }

  int currentBookmarkIndex = 0;
  String currentBookmarksShowing = "Ayah";
  updateBookmarkIndex(int value) {
    currentBookmarkIndex = value;
    switch (currentBookmarkIndex) {
      case 0:
        currentBookmarksShowing = AppStrings.ayahs;
        currentItemCount = arabicAyahs.length;
        break;
      case 1:
        currentBookmarksShowing = AppStrings.surahs;
        currentItemCount = surahs.length;
        break;
      default:
        return 0;
    }
    notifyListeners();
  }

  int currentItemCount = 0;
}

class BookmarkScreen extends riverpod.ConsumerWidget {
  static const id = 'bookmarkScreen';

  final bool isTranslationPage;
  final scrollController = ScrollController();

  BookmarkScreen({Key? key, required this.isTranslationPage}) : super(key: key);

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final bMP = ref.watch(bookmarkProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        appBar: isTranslationPage
            ? null
            : AppBar(
                backgroundColor: theme.canvasColor,
                title: Text(
                  AppLocalizations.of(context)!.bookMarks,
                ),
              ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Title(bMP: bMP, theme: theme),
            _BookmarksTabs(bMP: bMP, theme: theme),
            _Content(
              bMP: bMP,
              ref: ref,
              scrollController: scrollController,
            )
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final riverpod.WidgetRef ref;
  final ScrollController scrollController;
  const _Content({
    Key? key,
    required this.bMP,
    required this.ref,
    required this.scrollController,
  }) : super(key: key);

  final BookmarkController bMP;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScrollBarWidget(
        controller: scrollController,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          controller: scrollController,
          itemCount: bMP.currentItemCount,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            if (bMP.currentBookmarkIndex == 0) {
              return EachAyahWidget(
                  no: bMP.arabicAyahs[index].numberInSurah,
                  chapterNo: bMP.arabicAyahs[index].chapterNo,
                  arabic: bMP.arabicAyahs[index].text,
                  sajda: bMP.arabicAyahs[index].sajda ?? '',
                  translation: bMP.translationAyahs[index].text,
                  textDirectionString: bMP.arabicAyahs[index].direction,
                  textDirection: bMP.translationAyahs[index].direction == "ltr" ? TextDirection.ltr : TextDirection.rtl,
                  isReciting: bMP.translationAyahs[index].number == bMP.currentRecitingAyah,
                  audio: () {
                    bMP.reciteAyah(context: context, ref: ref, ayah: bMP.translationAyahs[index]);
                  },
                  copyText: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            '${bMP.arabicAyahs[index].text}﴿${arabicNumeric(bMP.arabicAyahs[index].numberInSurah)}﴾\n${bMP.translationAyahs[index].text}'));
                  },
                  share: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return StatusMaker(ayahNumber: bMP.translationAyahs[index].number);
                      },
                    ));
                  },
                  bookmark: () {
                    bMP.updateBookmarkAyah(
                        arabicAyah: bMP.arabicAyahs[index], translationAyah: bMP.translationAyahs[index]);
                  },
                  bookmarked: true);
            } else if (bMP.currentBookmarkIndex == 1) {
              return EachTextSurahWidget(
                  chapterNo: bMP.surahs[index].number.toString(),
                  chapterNameEn: bMP.surahs[index].englishName,
                  chapterNameAr: bMP.surahs[index].name,
                  chapterNametranslation: bMP.surahs[index].englishNameTranslation,
                  chapterType: bMP.surahs[index].revelationType,
                  chapterAyats: bMP.surahs[index].numberOfAyahs.toString(),
                  isFavourite: true,
                  tap: () {
                    bMP.chapterSelect(context: context, surah: bMP.surahs[index]);
                  },
                  likeButton: () {
                    bMP.updateBookmarkSurah(bMP.surahs[index]);
                  });
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
      ),
    );
  }
}

class _BookmarksTabs extends StatelessWidget {
  final BookmarkController bMP;
  final ThemeData theme;

  const _BookmarksTabs({
    Key? key,
    required this.bMP,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 40.0,
      padding: const EdgeInsets.only(
        top: 3.0,
        bottom: 3.0,
      ),
      child: CupertinoSegmentedControl<int>(
        groupValue: bMP.currentBookmarkIndex,
        borderColor: theme.primaryColor.withOpacity(0.4),
        selectedColor: theme.primaryColor,
        children: {
          0: Text(AppLocalizations.of(context)!.ayahs),
          1: Text(AppLocalizations.of(context)!.surahs),
        },
        onValueChanged: (int value) async {
          bMP.updateBookmarkIndex(value);
        },
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final BookmarkController bMP;
  final ThemeData theme;

  const _Title({
    Key? key,
    required this.bMP,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      '${bMP.currentItemCount} ${bMP.currentBookmarksShowing} ${AppLocalizations.of(context)!.found}',
      maxLines: 1,
      maxFontSize: 30,
      minFontSize: 10,
      style: theme.textTheme.displaySmall,
    );
  }
}
