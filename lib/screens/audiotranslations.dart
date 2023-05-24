import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:quran/utils/reciters/qurantranslations.dart';
import 'package:quran/screens/ayahbyayah.dart';
import 'package:quran/widgets/reuseablewidgets.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';

final audioTranslationProvider = riverpod.ChangeNotifierProvider.autoDispose((_) => AudioTranslationController());

class AudioTranslationController with ChangeNotifier {
  String selectedAudioTranslation = UC.hive.get(kSelectedAudioTranslation) ?? 'English';

  AudioTranslationController();

  TextEditingController textEditingController = TextEditingController();

  FocusNode focusNode = FocusNode();
  bool isSearching = false;

  updateSearch(bool _) {
    isSearching = _;

    notifyListeners();
  }

  void unfocusClear() {
    focusNode.unfocus();
    updateSearch(false);
    textEditingController.clear();
    searchByNameOrNumber('');
  }

  List<AudioSurahTranslation> totalTranslations = AudioSurahTranslation.quranTranslations;
  List<AudioSurahTranslation> foundTranslations = AudioSurahTranslation.quranTranslations;

  updateSelected(AudioSurahTranslation audioTranslation) {
    UC.hive.put(kSelectedAudioTranslation, audioTranslation.name);
    selectedAudioTranslation = audioTranslation.name;
    UC.uv.updateSelectedAudioTranslation(audioTranslation.name);
    notifyListeners();
    compute(resetSurahsDurations, true);
  }

  searchByNameOrNumber(String str) {
    if (str.isEmpty) {
      foundTranslations = totalTranslations;
      notifyListeners();
      return;
    }
    int value = int.tryParse(str) ?? 0;
    if (value != 0 && value <= 134) {
      List<AudioSurahTranslation> current = [totalTranslations[value]];

      foundTranslations = current;
      notifyListeners();
      return;
    } else {
      List<AudioSurahTranslation> current = [];
      for (int i = 0; i < totalTranslations.length; i++) {
        String lower = str.toLowerCase();

        final toMatch = RegExp(lower);
        if (toMatch.hasMatch(totalTranslations[i].name.toLowerCase()) ||
            toMatch.hasMatch(totalTranslations[i].nativeName.toLowerCase())) {
          current.add(totalTranslations[i]);
        }
      }

      foundTranslations = current;
      notifyListeners();
    }
  }
}

class AudioTranslationsScreen extends riverpod.ConsumerWidget {
  static const id = 'audioTranslationsScreen';

  AudioTranslationsScreen({Key? key}) : super(key: key);
  final ScrollController controller = ScrollController();
  @override
  Widget build(BuildContext context, ref) {
    final tP = ref.watch(audioTranslationProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        tP.unfocusClear();
        controller.dispose();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.canvasColor,
          appBar: AppBar(
            backgroundColor: theme.canvasColor,
            title: tP.isSearching
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        80.0,
                      ),
                    ),
                    child: CupertinoTextField(
                      autofocus: true,
                      focusNode: tP.focusNode,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                      keyboardType: TextInputType.text,
                      controller: tP.textEditingController,
                      onChanged: (String str) {
                        tP.searchByNameOrNumber(str);
                      },
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.searchTranslations,
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                child: InkWell(
                  onTap: () {
                    tP.updateSearch(true);
                  },
                  child: const Icon(
                    CupertinoIcons.search,
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
          body: ScrollBarWidget(
            controller: controller,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  delegate: _StickyHeaderDelegate(size: size, tP: tP, theme: theme),
                  pinned: true,
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: tP.foundTranslations.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredGrid(
                                columnCount: tP.foundTranslations.length,
                                position: index,
                                duration: const Duration(milliseconds: 475),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: AudioTranslationWidget(
                                      translationNo: (index + 1).toString(),
                                      translationNameEn: tP.foundTranslations[index].name,
                                      translationNameL: tP.foundTranslations[index].nativeName,
                                      isSelected: tP.foundTranslations[index].name == tP.selectedAudioTranslation,
                                      selectedTap: () {
                                        tP.updateSelected(tP.foundTranslations[index]);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Size size;
  final AudioTranslationController tP;
  final ThemeData theme;

  const _StickyHeaderDelegate({
    required this.size,
    required this.tP,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Center(
      child: Container(
        width: size.width,
        color: theme.canvasColor,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AutoSizeText(
          '${tP.totalTranslations.length} ${AppLocalizations.of(context)!.audioTranslationsAvailable}',
          textAlign: TextAlign.center,
          maxLines: 1,
          style: theme.textTheme.headline4,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
