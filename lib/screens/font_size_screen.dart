import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/screens/settings.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FontSizeScreen extends ConsumerWidget {
  static const id = "fontSizeScreen";
  const FontSizeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sP = ref.watch(settingsProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: theme.canvasColor,
          centerTitle: true,
          title: Text(AppLocalizations.of(context)!.changeFontSize),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${AppLocalizations.of(context)!.arabicFontSize}:  ${sP.arabicFontSize}px',
                  style: const TextStyle(
                    height: 2.2,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              Slider(
                value: sP.arabicFontSize,
                onChanged: sP.updateArabicFontSize,
                min: 10.0,
                max: 50.0,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${AppLocalizations.of(context)!.translationsFontSize}:  ${sP.translationFontSize}px',
                  style: const TextStyle(
                    height: 2.2,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              Slider(
                value: sP.translationFontSize,
                onChanged: sP.updateTranslationFontSize,
                min: 10.0,
                max: 50.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
