// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:quran/main.dart';
import 'package:quran/screens/res/app_colors.dart';
import 'package:quran/screens/res/app_strings.dart';

import 'package:quran/widgets/customanimations.dart';
import 'package:quran/widgets/reuseablewidgets.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'ayahbyayah.dart';

class EachChapterFunctions {}

EachChapterFunctions functions = EachChapterFunctions();
final eachSurahTextProvider = riverpod.ChangeNotifierProvider.autoDispose
    .family<EachSurahTextController, int>((_, chapterNo) => EachSurahTextController(chapterNo));

class EachSurahTextController with ChangeNotifier {
  void startupServices(int chapterNo) async {}

  List<GlobalKey> textLocation = [];

  final int currentChapterNo;
  EachSurahTextController(this.currentChapterNo) {
    scroller.addListener(_scrollListener);
  }
  bool chapterNameinArabic = true;

  double currentPixels = 0.0;
  double maximumPixels = 100.0;

  bool isBeingChanged = false;

  bool isPlaying = false;
  bool isReading = false;

  startReading() {
    int? durationofScroll = 12;

    int speed = UC.hive.get('speed') ?? 1;
    isReading
        ? scroller.jumpTo(scroller.position.pixels)
        : scroller.animateTo(scroller.position.maxScrollExtent,
            duration: Duration(seconds: durationofScroll ~/ speed), curve: Curves.linear);
    isReading = !isReading;
    notifyListeners();
  }

  double totalDurationInSec = 0.0;
  int currentPositioninSec = 0;
  final int pixelsToScroll = 500;
  ScrollController scroller = ScrollController();

  _scrollListener() {
    ScrollDirection userScroll = scroller.position.userScrollDirection;
    double currentPixel = scroller.position.pixels;
    currentPixels = currentPixel;

    if (userScroll == ScrollDirection.forward) {
      if (isPlaying) {
        scroller.jumpTo(scroller.position.pixels - pixelsToScroll);
        scroller.animateTo(scroller.position.maxScrollExtent,
            duration: Duration(seconds: (totalDurationInSec - currentPositioninSec).toInt()), curve: Curves.linear);
      } else if (isReading) {
        scroller.jumpTo(scroller.position.pixels - pixelsToScroll);
        int durationofScroll = 12;
        scroller.animateTo(scroller.position.maxScrollExtent,
            duration: Duration(seconds: durationofScroll ~/ UC.hive.get('speed', defaultValue: 1)),
            curve: Curves.linear);
      }
    } else if (userScroll == ScrollDirection.reverse) {
      if (isPlaying) {
        scroller.jumpTo(scroller.position.pixels + pixelsToScroll);
        scroller.animateTo(scroller.position.maxScrollExtent,
            duration: Duration(seconds: (totalDurationInSec - currentPositioninSec).toInt()), curve: Curves.linear);
      } else if (isReading) {
        scroller.jumpTo(scroller.position.pixels + pixelsToScroll);
        int durationofScroll = 12;
        scroller.animateTo(scroller.position.maxScrollExtent,
            duration: Duration(seconds: durationofScroll ~/ UC.hive.get('speed', defaultValue: 1)),
            curve: Curves.linear);
      }
    }
    maximumPixels = scroller.position.maxScrollExtent;
    currentPixels = scroller.position.pixels;
  }

  List<Ayah> foundChapterText = [];
  Surah? surah;
  Ayah? lastVisibleAyah;
  Ayah? previouslyReadAyah;
  Widget textWidget = const CircularProgressIndicator(
    color: Colors.green,
  );
  updateLastVisibleAyah(Ayah ayah) {
    lastVisibleAyah = ayah;
  }

  generateChaptersText(int surahNo) async {
    List<Ayah> chapterText = await compute(getTextBySurahNo, surahNo);

    surah = UC.isar.surahs.filter().numberEqualTo(surahNo).findFirstSync();
    foundChapterText = chapterText;
    textLocation = List.generate(foundChapterText.length, (i) => GlobalKey());
    for (Ayah ayah in chapterText) {
      if (ayah.lastRead != null) {
        previouslyReadAyah = ayah;
      }
    }
  }

  goToLastReadAyah() {
    previouslyReadAyah != null
        ? Scrollable.ensureVisible(textLocation[previouslyReadAyah!.numberInSurah - 1].currentContext!)
        : null;
  }

  gotoChapter(int chapterNo) {
    generateChaptersText(chapterNo);
  }

  generateTextWidget(
    BuildContext context,
    double fontSize,
  ) {
    List<Ayah> surahText = foundChapterText;

    if (surahText.isEmpty) {
      return Container();
    }

    List<InlineSpan> allAyats = [];
    if (surahText[0].chapterNo != 1 && surahText[0].chapterNo != 9) {
      allAyats.add(
        TextSpan(
          text: surahText[0].text.split("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")[1],
        ),
      );
      allAyats.add(stringCounter(0, textLocation[0], () {
        updateLastVisibleAyah(surahText[0]);
      }));
    } else {
      if (surahText[0].chapterNo != 9) {
        if (surahText[0].chapterNo != 1) {
          allAyats.add(stringCounter(0, textLocation[0], () {
            updateLastVisibleAyah(surahText[0]);
          }));
        }

        allAyats.add(
          TextSpan(
            text: surahText[0].text.split("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")[1],
          ),
        );
      } else {
        allAyats.add(stringCounter(0, textLocation[0], () {
          updateLastVisibleAyah(surahText[0]);
        }));
      }
    }

    for (int i = 1; i < surahText.length; i++) {
      allAyats.add(
        TextSpan(
          text: surahText[i].text,
          children: [
            stringCounter(i, textLocation[i], () {
              updateLastVisibleAyah(surahText[i]);
            })
          ],
          style: TextStyle(
            color: Theme.of(context).textTheme.headline1!.color,
            fontSize: fontSize,
            fontFamily: "ScheherazadeNew-Bold",
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      );
    }

    textWidget = RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      text: TextSpan(
          text: surahText[0].chapterNo == 9 ? surahText[0].text : null,
          style: TextStyle(
            color: Theme.of(context).textTheme.headline1!.color,
            fontSize: fontSize,
            fontFamily: "ScheherazadeNew-Bold",
          ),
          children: allAyats),
    );
    notifyListeners();
  }

  Future<Ayah?> removePreviouslyReadAyah(int chapterNo) async {
    List<Ayah> previouslyReadAyahs = await UC.isar.ayahs
        .filter()
        .chapterNoEqualTo(chapterNo)
        .and()
        .languageEqualTo(kArabicText)
        .and()
        .not()
        .lastReadIsNull()
        .sortByLastRead()
        .findAll();
    previouslyReadAyah = previouslyReadAyahs.isNotEmpty ? previouslyReadAyahs.last : null;

    for (Ayah element in previouslyReadAyahs) {
      element.lastRead = null;
    }
    if (previouslyReadAyahs.isNotEmpty) {
      UC.isar.writeTxn(() {
        return UC.isar.ayahs.putAll(previouslyReadAyahs);
      });
    }
    return previouslyReadAyah;
  }

  persistLastVisibleAyah() {
    removePreviouslyReadAyah(surah!.number);
    if (lastVisibleAyah != null) {
      int time = DateTime.now().millisecondsSinceEpoch;
      lastVisibleAyah?.lastRead = time;
      surah?.lastRead = time;
      UC.isar.writeTxn(() {
        return UC.isar.surahs.put(surah!);
      });
      UC.isar.writeTxn(() {
        return UC.isar.ayahs.put(lastVisibleAyah!);
      });
    }
  }

  showLastReadSnackBar(BuildContext context) async {
    await generateChaptersText(currentChapterNo);
    generateTextWidget(context, UC.uv.selectedArabicFontSize);

    snackBarShowed = true;
    await Future.delayed(const Duration(seconds: 1));

    if (previouslyReadAyah == null) {
      return;
    }
    final snackBar = SnackBar(
      content: const MyCustomAnimation(
        duration: Duration(seconds: 3),
      ),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 100),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.continueRead,
        textColor: AppColors.lightGreen,
        onPressed: goToLastReadAyah,
      ),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool snackBarShowed = false;
}

class EachQuranText extends riverpod.ConsumerWidget {
  final ScrollController scrollController = ScrollController();
  static const String id = 'eachQuranText';
  final int chapterNo;
  EachQuranText({
    Key? key,
    required this.chapterNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final eSP = ref.watch(eachSurahTextProvider(chapterNo));
    if (!eSP.snackBarShowed) {
      eSP.showLastReadSnackBar(context);
    }

    return WillPopScope(
      onWillPop: () async {
        await eSP.persistLastVisibleAyah();
        Navigator.pop(context, eSP.lastVisibleAyah);
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).canvasColor,
          appBar: AppBar(
            automaticallyImplyLeading: true,
            backgroundColor: AppColors.transparent,
            title: const Text(
              AppStrings.quranApp,
            ),
          ),
          body: ScrollBarWidget(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Column(
                  children: [
                    TitleWidget(name: eSP.surah?.name ?? ''),
                    const SizedBox(height: 30),
                    eSP.foundChapterText.isEmpty ? const SizedBox() : _CountWidget(eSP: eSP),
                    eSP.textWidget,
                    _BottomWidget(eSP: eSP, scrollController: scrollController)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomWidget extends StatelessWidget {
  final EachSurahTextController eSP;
  final ScrollController scrollController;

  const _BottomWidget({
    Key? key,
    required this.eSP,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () async {
            await eSP.persistLastVisibleAyah();
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.read_more,
            size: 30,
            color: Theme.of(context).primaryColor,
          ),
        ),
        IconButton(
          onPressed: () => scrollController.jumpTo(0.0),
          icon: Icon(
            Icons.arrow_circle_up,
            size: 30,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

class _CountWidget extends StatelessWidget {
  final EachSurahTextController eSP;

  const _CountWidget({
    Key? key,
    required this.eSP,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        eSP.foundChapterText[0].chapterNo == 1 ? Flexible(flex: 1, child: justCount(0)) : const SizedBox(),
        eSP.foundChapterText[0].chapterNo == 9
            ? const SizedBox()
            : const Flexible(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 18.0),
                  child: AutoSizeText(
                    "﻿بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                    textAlign: TextAlign.justify,
                    minFontSize: 30,
                    maxFontSize: 40,
                    maxLines: 1,
                  ),
                ),
              ),
      ],
    );
  }
}



class BottomNavigationChild extends StatelessWidget {
  final IconData? icon;
  final String? info;
  final Function? func;
  final bool isSelected;
  const BottomNavigationChild({Key? key, this.icon, this.info, this.func, this.isSelected = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: GestureDetector(
        onTap: func as void Function()?,
        child: ListTile(
          selected: isSelected,
          title: Icon(
            icon,
            color: isSelected ? const Color(0XFF29BB89) : Colors.white,
            size: 40.0,
          ),
          subtitle: Text(
            info!,
            style: TextStyle(
              color: isSelected ? const Color(0XFF29BB89) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
