import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:quran/assets/quranformat.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/fastfunctions.dart';

import 'package:quran/main.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:quran/widgets/reuseablewidgets.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'ayahbyayah.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final textTranslationProvider = riverpod.ChangeNotifierProvider((_) => TextTranslationController());

class TextTranslationController with ChangeNotifier {
  TextTranslationController() {
    generateTextTranslations();
  }

  TextEditingController textEditingController = TextEditingController();

  FocusNode focusNode = FocusNode();
  bool isSearching = false;
  String currentDownloading = '';

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

  List<TextTranslation> totalTextTranslations = [];
  List<TextTranslation> foundTextTranslations = [];

  generateTextTranslations() {
    List<TextTranslation> textTranslations = UC.isar.textTranslations.where().sortByLanguage().findAllSync();
    totalTextTranslations = textTranslations;
    foundTextTranslations = textTranslations;
  }

  updateBookmark(TextTranslation textTranslation) {
    textTranslation.bookmarked = !(textTranslation.bookmarked);
    UC.isar.writeTxn(() {
      return UC.isar.textTranslations.put(textTranslation);
    });
    notifyListeners();
  }

  Future<bool> downloadTranslation(TextTranslation textTranslation, BuildContext context) async {
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

  updateSelected(TextTranslation textTranslation, BuildContext context) async {
    if (textTranslation.isDownloaded == false) {
      currentDownloading = textTranslation.identifier;
      notifyListeners();
      bool downloaded = await downloadTranslation(textTranslation, context);
      if (downloaded == false) return false;
      textTranslation.isDownloaded = true;
    }

    TextTranslation? alreadySelectedTranslation;

    for (TextTranslation tTranslation in totalTextTranslations) {
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

  searchByNameOrNumber(String str) {
    if (str.isEmpty) {
      foundTextTranslations = totalTextTranslations;
      notifyListeners();
      return;
    }
    int value = int.tryParse(str) ?? 0;
    if (value != 0 && value <= 134) {
      List<TextTranslation> current = [totalTextTranslations[value]];

      foundTextTranslations = current;
      notifyListeners();
      return;
    } else {
      List<TextTranslation> current = [];
      for (int i = 0; i < totalTextTranslations.length; i++) {
        String lower = str.toLowerCase();

        final toMatch = RegExp(lower);
        if (toMatch.hasMatch(totalTextTranslations[i].name.toLowerCase()) ||
            toMatch.hasMatch(totalTextTranslations[i].englishName.toLowerCase()) ||
            toMatch.hasMatch(totalTextTranslations[i].language.toLowerCase()) ||
            toMatch.hasMatch(languageCodes[totalTextTranslations[i].language]!.toLowerCase())) {
          current.add(totalTextTranslations[i]);
        }
      }

      foundTextTranslations = current;
      notifyListeners();
    }
  }
}

class AyahTranslationsScreen extends riverpod.ConsumerWidget {
  static const id = 'verseTranslationsScreen';
  AyahTranslationsScreen({Key? key}) : super(key: key);
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context, ref) {
    final tP = ref.watch(textTranslationProvider);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        tP.unfocusClear();
        controller.dispose();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).canvasColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor,
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
                  delegate: _StickyHeaderDelegate(tP: tP, theme: theme),
                  pinned: true,
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: tP.foundTextTranslations.length,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredGrid(
                                columnCount: tP.foundTextTranslations.length,
                                position: index,
                                duration: const Duration(milliseconds: 100),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: EachTextTranslationWidget(
                                      translationNo: (index + 1).toString(),
                                      translationNameEn: languageCodes[tP.foundTextTranslations[index].language]!,
                                      translationNameL: tP.foundTextTranslations[index].englishName,
                                      type: tP.foundTextTranslations[index].type.toUpperCase(),
                                      isDownloading:
                                          tP.foundTextTranslations[index].identifier == tP.currentDownloading,
                                      isSelected: tP.foundTextTranslations[index].isSelected,
                                      isBookmarked: tP.foundTextTranslations[index].bookmarked,
                                      bookmarkTap: () {
                                        tP.updateBookmark(tP.foundTextTranslations[index]);
                                      },
                                      selectedTap: () {
                                        tP.updateSelected(tP.foundTextTranslations[index], context);
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
  final TextTranslationController tP;
  final ThemeData theme;

  const _StickyHeaderDelegate({
    required this.tP,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        width: size.width,
        color: theme.canvasColor,
        child: AutoSizeText(
          '${tP.totalTextTranslations.length} ${AppLocalizations.of(context)!.ayahTranslationsAvailable}',
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
