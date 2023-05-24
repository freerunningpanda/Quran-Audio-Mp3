import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../screens/res/app_colors.dart';
import 'decoration_border_widget.dart';

class RecentlyRecitedSurah extends StatelessWidget {
  final String name;
  final String description;
  final double progress;
  final Function recite;
  const RecentlyRecitedSurah({
    Key? key,
    required this.recite,
    required this.description,
    required this.name,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: recite as void Function(),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Column(
              children: [
                DecorationBorderWidget(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        width: size.width / 2,
                        child: Center(
                          child: Text(name, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                        ),
                      ),
                      LinearProgressIndicator(
                        value: progress,
                        color: AppColors.lightGreen,
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AutoSizeText(
              description,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
