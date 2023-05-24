import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/utils/commonutils.dart';

import '../utils/audiostate.dart';
import '../widgets/recently_recited_surahs.dart';
import 'ayahbyayah.dart';
import 'home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecentlyListenSurahs extends ConsumerWidget {
  static const id = 'recentlyListenSurahs';
  final ScrollController scrollController = ScrollController();

  RecentlyListenSurahs({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final hP = ref.watch(homeProvider);
    final orientation = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        title: Text(
          AppLocalizations.of(context)!.recentlyRecitedSurahs,
        ),
      ),
      body: ScrollBarWidget(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView(
            children: [
              GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: orientation ? 2 : 3,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 175,
                  ),
                  itemCount: hP.lastRecitedSurahs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return RecentlyRecitedSurah(
                      recite: () {
                        ref
                            .read(audioStateProvider)
                            .initializeOldRecitingSurahsIfExist(hP.lastRecitedSurahs[index], startReciting: true);
                        hP.refresh(hP.lastRecitedSurahs[index]);
                      },
                      name: hP.lastRecitedSurahs[index].name,
                      description: hP.lastRecitedSurahs[index].lastRecited!.currentTime,
                      progress: (hP.lastRecitedSurahs[index].currentDuration ?? 0) /
                          (hP.lastRecitedSurahs[index].totalDuration ?? 1).toDouble(),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
