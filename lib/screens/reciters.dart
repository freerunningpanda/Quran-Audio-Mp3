import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:quran/widgets/reuseablewidgets.dart';

final reciterProvider = riverpod.ChangeNotifierProvider((_) => ReciterController());

class ReciterController with ChangeNotifier {
  ReciterController() {
    generateReciters();
  }

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

  List<Reciter> totalReciters = [];
  List<Reciter> foundReciters = [];

  generateReciters() {
    List<Reciter> reciters = UC.isar.reciters.where().sortByName().findAllSync();
    totalReciters = reciters;
    foundReciters = reciters;
  }

  updateBookmark(Reciter reciter) {
    reciter.bookmarked = !(reciter.bookmarked);
    UC.isar.writeTxn(() {
      return UC.isar.reciters.put(reciter);
    });
    notifyListeners();
  }

  updateSelected(Reciter reciter) {
    Reciter? alreadySelectedReciter;

    for (Reciter reciter in totalReciters) {
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
    UC.uv.updateSelectedReciter(reciter);
    notifyListeners();
    compute(resetSurahsDurations, true);
  }

  searchByNameOrNumber(String str) {
    if (str.isEmpty) {
      foundReciters = totalReciters;
      notifyListeners();
      return;
    }
    int value = int.tryParse(str) ?? 0;
    if (value != 0 && value <= 134) {
      List<Reciter> current = [totalReciters[value]];

      foundReciters = current;
      notifyListeners();
      return;
    } else {
      List<Reciter> current = [];
      for (int i = 0; i < totalReciters.length; i++) {
        String lower = str.toLowerCase();

        final toMatch = RegExp(lower);
        if (toMatch.hasMatch(totalReciters[i].name.toLowerCase())) {
          current.add(totalReciters[i]);
        }
      }

      foundReciters = current;
      notifyListeners();
    }
  }
}

class RecitersScreen extends riverpod.ConsumerWidget {
  static const id = 'Reciters';

  RecitersScreen({Key? key}) : super(key: key);
  final ScrollController scroll = ScrollController();

  @override
  Widget build(BuildContext context, ref) {
    final rP = ref.watch(reciterProvider);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        rP.unfocusClear();
        scroll.dispose();
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.canvasColor,
          appBar: AppBar(
            backgroundColor: theme.canvasColor,
            title: rP.isSearching
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        80.0,
                      ),
                    ),
                    child: CupertinoTextField(
                      autofocus: true,
                      focusNode: rP.focusNode,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                      ),
                      keyboardType: TextInputType.text,
                      controller: rP.textEditingController,
                      onChanged: (String str) {
                        rP.searchByNameOrNumber(str);
                      },
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: theme.primaryColor),
                      ),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.searchReciters,
                  ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                child: InkWell(
                  onTap: () {
                    rP.updateSearch(true);
                  },
                  child: const Icon(
                    CupertinoIcons.search,
                    size: 20.0,
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                delegate: _StickyHeaderDelegate(rP: rP, theme: theme),
                pinned: true,
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimationLimiter(
                            child: ListView.builder(
                                itemCount: rP.foundReciters.length,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return AnimationConfiguration.staggeredGrid(
                                    columnCount: rP.foundReciters.length,
                                    position: index,
                                    duration: const Duration(milliseconds: 475),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: EachReciterWidget(
                                          reciterNo: index + 1,
                                          reciterName: rP.foundReciters[index].name,
                                          isBookmarked: rP.foundReciters[index].bookmarked,
                                          bookmarkTap: () {
                                            rP.updateBookmark(rP.foundReciters[index]);
                                          },
                                          isSelected: rP.foundReciters[index].isSelected,
                                          selected: () {
                                            rP.updateSelected(rP.foundReciters[index]);
                                          },
                                          server: rP.foundReciters[index].identifier,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ReciterController rP;
  final ThemeData theme;

  const _StickyHeaderDelegate({
    required this.rP,
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
          '${rP.totalReciters.length} ${AppLocalizations.of(context)!.recitersAvailable}',
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
