import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:quran/utils/commonutils.dart';

import '../database/isarschema.dart';
import '../screens/res/app_colors.dart';
import 'decoration_border_widget.dart';

class LastReadSurah extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;
  const LastReadSurah({Key? key, required this.surah, required this.ayah}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            DecorationBorderWidget(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          AutoSizeText('﴾${surah.name}﴿', maxLines: 1, style: theme.textTheme.bodyLarge),
                          AutoSizeText('${surah.number} ${surah.englishName}', style: theme.textTheme.bodyLarge),
                          AutoSizeText(
                            "Read ${ayah.numberInSurah} of ${surah.numberOfAyahs} Ayahs",
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      LinearProgressIndicator(
                        value: ayah.numberInSurah / surah.numberOfAyahs,
                        color: AppColors.lightGreen,
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AutoSizeText(
              'Read ${surah.lastRead!.currentTime}',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
