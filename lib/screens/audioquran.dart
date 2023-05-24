import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/audiostate.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran/widgets/reuseablewidgets.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import '../widgets/player_close.dart';
import '../widgets/player_open.dart';

final audioQuranProvider = riverpod.ChangeNotifierProvider((_) => AudioQuranController());

class AudioQuranController with ChangeNotifier {
  List<Surah> totalSurahs = <Surah>[];
  List<Surah> foundSurahs = <Surah>[];

  Reciter selectedReciter = UC.uv.selectedReciter;
  String selectedTranslation = UC.uv.selectedAudioTranslation;
  AudioType currentAudioType = UC.uv.selectedAudioType;

  int currentReciting = UC.hive.get('lastRecited') ?? 0;
  bool buffering = false;
  bool pause = false;
  generateChaptersList() async {
    List<Surah> chapters = await compute(getAllSurahs, true);
    totalSurahs = chapters;
    foundSurahs = chapters;

    notifyListeners();
  }

  searchByNameOrNumber(String str) {
    if (str.isEmpty) {
      foundSurahs = totalSurahs;
      notifyListeners();
    }
    int value = int.tryParse(str) ?? 0;
    if (value != 0 && value < 115) {
      List<Surah> current = [];
      for (int i = 0; i < totalSurahs.length; i++) {
        final toMatch = RegExp('$value');
        if (toMatch.hasMatch(totalSurahs[i].number.toString())) {
          current.add(totalSurahs[i]);
        }
      }

      foundSurahs = current;
      notifyListeners();
    } else {
      List<Surah> current = [];
      for (int i = 0; i < totalSurahs.length; i++) {
        String lower = str.toLowerCase();

        final toMatch = RegExp(lower);
        if (toMatch.hasMatch(totalSurahs[i].englishName.toLowerCase())) {
          current.add(totalSurahs[i]);
        }
      }

      foundSurahs = current;
      notifyListeners();
    }
  }

  reciteThisSurah(Surah surah, {required riverpod.WidgetRef ref}) {
    Reciter selectedReciter = UC.uv.selectedReciter;
    String selectedTranslation = UC.uv.selectedAudioTranslation;

    String? album;
    String reciterName = selectedReciter.name;

    String translationServer = selectedTranslation;
    String reciterUrl =
        'https://server${selectedReciter.serverNo}.mp3quran.net/${selectedReciter.identifier}/chapter.mp3';
    String translationUrl = 'http://www.truemuslims.net/download.php?path=Quran/$translationServer/chapter.mp3';
    late String url;
    if (currentAudioType == AudioType.arabic) {
      url = reciterUrl;
      album = reciterName;
    } else {
      url = translationUrl;
      album = translationServer;
    }

    List<AudioSource> chapters = [];
    for (int i = 0; i < totalSurahs.length; i++) {
      int finalIndex = i + 1;
      String newIndex;

      if (finalIndex < 10) {
        newIndex = '00$finalIndex';
      } else if (finalIndex < 100 && finalIndex >= 10) {
        newIndex = '0$finalIndex';
      } else {
        newIndex = '$finalIndex';
      }

      chapters.add(LockCachingAudioSource(
        Uri.parse(url.replaceAll('chapter', newIndex)),
        cacheFile: File('${UC.uv.appDirectoryPath}/$album/$newIndex'),
        tag: MediaItem(
            id: '$i', album: album, title: totalSurahs[i].englishName, artist: album, extras: totalSurahs[i].toJson()),
      ));
    }

    ref.read(audioStateProvider).reciteSurah(chapters, surah, album);
  }

  updateCurrentAudioType(AudioType newAudioType) {
    currentAudioType = newAudioType;
    UC.uv.updateSelectedAudioType(newAudioType);

    notifyListeners();
    compute(resetSurahsDurations, true);
  }

  bool isSearching = false;
  FocusNode focusNode = FocusNode();
  updateSearch(bool _) {
    isSearching = _;
    focusNode.requestFocus();
    notifyListeners();
  }

  void unfocusClear() {
    searchByNameOrNumber('');
    focusNode.unfocus();
    isSearching = false;
    notifyListeners();
  }

  AudioQuranController() {
    generateChaptersList();
  }
}

class QuranAudio extends riverpod.ConsumerWidget {
  static const String id = 'QuranAudio';

  QuranAudio({Key? key}) : super(key: key);
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final audioProvider = ref.watch(audioQuranProvider);
    final aSP = ref.watch(audioStateProvider);
    return WillPopScope(
      onWillPop: () async {
        audioProvider.unfocusClear();
        textEditingController.clear();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.canvasColor,
          appBar: AppBar(
            backgroundColor: theme.canvasColor,
            title: audioProvider.isSearching
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        80.0,
                      ),
                    ),
                    child: CupertinoTextField(
                      focusNode: audioProvider.focusNode,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                      keyboardType: TextInputType.text,
                      controller: textEditingController,
                      onChanged: (String str) {
                        audioProvider.searchByNameOrNumber(str);
                      },
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: theme.primaryColor),
                      ),
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
                    audioProvider.updateSearch(true);
                  },
                  child: const Icon(
                    CupertinoIcons.search,
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 35.0,
                margin: const EdgeInsets.only(
                  top: 3.0,
                  bottom: 3.0,
                ),
                child: CupertinoSegmentedControl<AudioType>(
                  groupValue: audioProvider.currentAudioType,
                  borderColor: theme.primaryColor,
                  selectedColor: theme.primaryColor,
                  unselectedColor: theme.canvasColor,
                  children: {
                    AudioType.arabic: Text(AppLocalizations.of(context)!.arabic),
                    AudioType.translation: Text(AppLocalizations.of(context)!.translation),
                  },
                  onValueChanged: (AudioType audioType) async {
                    audioProvider.updateCurrentAudioType(audioType);
                    ref.read(audioStateProvider).player.stop();
                  },
                ),
              ),
              Expanded(
                child: Scrollbar(
                  radius: const Radius.circular(
                    10.0,
                  ),
                  thickness: 15.0,
                  interactive: true,
                  child: AnimationLimiter(
                    child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10),
                        itemExtent: 100,
                        itemCount: audioProvider.foundSurahs.length,
                        itemBuilder: (context, index) {
                          return AnimationConfiguration.staggeredGrid(
                            columnCount: audioProvider.foundSurahs.length,
                            position: index,
                            duration: const Duration(milliseconds: 475),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: EachAudioSurahWidget(
                                  chapterNo: audioProvider.foundSurahs[index].number.toString(),
                                  chapterNameEn: audioProvider.foundSurahs[index].englishName,
                                  chapterNameAr: audioProvider.foundSurahs[index].name,
                                  chapterType: audioProvider.foundSurahs[index].revelationType,
                                  chapterAyats: audioProvider.foundSurahs[index].numberOfAyahs.toString(),
                                  isFavourite: audioProvider.foundSurahs[index].bookmarked,
                                  isRepeat: false,
                                  isReciting:
                                      audioProvider.foundSurahs[index].number == aSP.currentRecitingSurah?.number,
                                  playTap: () {
                                    audioProvider.reciteThisSurah(audioProvider.foundSurahs[index], ref: ref);
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: OpenContainer(
            closedBuilder: (context, action) => const PlayerClose(),
            closedElevation: 20.0,
            closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            )),
            openBuilder: (context, action) => PlayerOpen(),
          ),
        ),
      ),
    );
  }
}
