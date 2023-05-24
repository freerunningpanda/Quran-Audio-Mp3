import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/last_read_surahs.dart';
import 'ayahbyayah.dart';
import 'eachsurahtext.dart';
import 'home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecentlyReadSurahs extends ConsumerWidget {
  static const id = 'recentlyReadSurahs';
  final ScrollController scrollController = ScrollController();

  RecentlyReadSurahs({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final hP = ref.watch(homeProvider);
    final orientation = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        title: Text(
          AppLocalizations.of(context)!.recentlyReadSurahs,
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
                itemCount: hP.lastReadTextAyahs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EachQuranText(chapterNo: hP.lastReadTextSurahs[index].number),
                        ),
                      );
                      await hP.generateLastReadValues();
                    },
                    child: LastReadSurah(
                      surah: hP.lastReadTextSurahs[index],
                      ayah: hP.lastReadTextAyahs[index],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
