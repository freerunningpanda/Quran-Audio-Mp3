import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quran/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:quran/widgets/ayahcount.dart';
import 'package:quran/widgets/customanimations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../utils/audiostate.dart';
import '../screens/res/app_assets.dart';
import '../screens/res/app_colors.dart';
import '../screens/res/app_typography.dart';
import 'decoration_border_widget.dart';
import 'quran_icons.dart';

Map<String, String> arabicNumbers = {
  '0': '٠',
  '1': '١',
  '2': '٢',
  '3': '٣',
  '4': '٤',
  '5': '٥',
  '6': '٦',
  '7': '٧',
  '8': '٨',
  '9': '٩'
};
String arabicNumeric(int i) {
  String mathNumbers = i.toString();
  String finalString = '';

  for (String character in mathNumbers.characters) {
    finalString = finalString + arabicNumbers[character]!;
  }
  return finalString;
}

showToast(
    {required BuildContext context,
    required Widget content,
    Duration duration = const Duration(seconds: 4),
    Color color = Colors.green,
    SnackBarAction? action}) {
  final snackBar = SnackBar(
    content: CountDownAnimation(
      duration: duration,
      color: color,
      child: content,
    ),
    action: action,
    duration: duration,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final TextDirection textDirection;
  final Duration animationDuration, backDuration, pauseDuration;

  const MarqueeWidget({
    Key? key,
    required this.child,
    this.direction = Axis.horizontal,
    this.textDirection = TextDirection.ltr,
    this.animationDuration = const Duration(milliseconds: 6000),
    this.backDuration = const Duration(milliseconds: 800),
    this.pauseDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: 50.0);
    WidgetsBinding.instance.addPostFrameCallback(scroll);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: widget.direction,
      controller: scrollController,
      child: widget.child,
    );
  }

  jumpToEnd() {
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  void scroll(_) async {
    while (scrollController.hasClients) {
      widget.textDirection == TextDirection.rtl ? jumpToEnd() : null;
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          widget.textDirection == TextDirection.rtl
              ? scrollController.position.minScrollExtent
              : scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
        );
      }
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }
}

class GlassMorphism extends StatelessWidget {
  final Widget child;
  final double start;
  final double end;
  final Color color;
  const GlassMorphism({
    Key? key,
    required this.child,
    required this.start,
    required this.end,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(start),
                color.withOpacity(end),
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class CircleGlassMorphism extends StatelessWidget {
  final Widget child;
  final double start;
  final double end;
  final Color color;
  const CircleGlassMorphism({
    Key? key,
    required this.child,
    required this.start,
    required this.end,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(start),
              color.withOpacity(end),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}

class EachAudioSurahWidget extends StatelessWidget {
  final String chapterNo;
  final String chapterNameEn;
  final String chapterNameAr;
  final String chapterType;
  final String chapterAyats;
  final bool? isFavourite;
  final bool? isRepeat;
  final bool isReciting;
  final Function playTap;

  const EachAudioSurahWidget(
      {Key? key,
      required this.chapterNo,
      required this.chapterNameEn,
      required this.chapterNameAr,
      required this.chapterType,
      required this.chapterAyats,
      this.isFavourite,
      this.isRepeat,
      required this.isReciting,
      required this.playTap})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: playTap as void Function()?,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DecorationBorderWidget(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${int.parse(chapterNo)}. $chapterNameEn',
                        style: theme.textTheme.titleLarge?.copyWith(
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '$chapterType - $chapterAyats Ayats',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.primaryColorLight,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.play_circle_outlined,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EachAyahWidget extends StatefulWidget {
  final int no;

  final int chapterNo;
  final String arabic;
  final String sajda;
  final String translation;
  final String textDirectionString;
  final Function copyText;
  final Function audio;
  final Function share;
  final Function bookmark;
  final bool isReciting;
  final TextDirection textDirection;
  final bool bookmarked;
  const EachAyahWidget({
    Key? key,
    required this.no,
    required this.chapterNo,
    required this.arabic,
    required this.sajda,
    required this.translation,
    required this.textDirectionString,
    required this.textDirection,
    required this.copyText,
    required this.audio,
    required this.share,
    required this.bookmark,
    required this.bookmarked,
    this.isReciting = false,
  }) : super(key: key);

  @override
  State<EachAyahWidget> createState() => _EachAyahWidgetState();
}

class _EachAyahWidgetState extends State<EachAyahWidget> {
  AudioType currentAudioType = UC.uv.selectedAudioType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DecorationBorderWidget(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: ScheherazadeNewBold(
                arabic: widget.arabic,
                number: widget.no,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: NotoNastaliqUrduRegular(
                text: widget.translation,
                textDirection: widget.textDirection,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      widget.bookmark();
                    },
                    child: Icon(
                      widget.bookmarked ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      size: 20.0,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (currentAudioType == AudioType.arabic) {
                        await widget.audio();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.switchToArabic),
                          ),
                        );
                      }
                    },
                    child: Icon(
                      widget.isReciting ? Icons.pause : Icons.play_arrow,
                      size: 25.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioTranslationWidget extends StatelessWidget {
  final String translationNo;
  final String translationNameEn;
  final String translationNameL;
  final bool isSelected;
  final Function selectedTap;

  const AudioTranslationWidget({
    Key? key,
    required this.translationNo,
    required this.translationNameEn,
    required this.translationNameL,
    required this.isSelected,
    required this.selectedTap,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      child: Column(
        children: [
          ListTile(
            leading: CounterWidget(count: int.parse(translationNo)),
            title: Text(
              translationNameEn,
              style: theme.textTheme.headline6,
            ),
            subtitle: Text(
              translationNameL,
              style: Theme.of(context).textTheme.subtitle2?.copyWith(
                    color: AppColors.darkGrey,
                  ),
            ),
            trailing: IconButton(
              onPressed: selectedTap as void Function()?,
              icon: isSelected
                  ? Icon(
                      Icons.check,
                      color: theme.primaryColor,
                      size: 30,
                    )
                  : const Icon(
                      Icons.add_rounded,
                      size: 30,
                    ),
            ),
          ),
          Divider(
            color: theme.shadowColor,
            thickness: 0.2,
          )
        ],
      ),
    );
  }
}

class EachReciterWidget extends StatefulWidget {
  final int reciterNo;
  final String reciterName;
  final bool isSelected;
  final Function selected;
  final bool isBookmarked;
  final Function bookmarkTap;
  final String server;

  const EachReciterWidget(
      {Key? key,
      required this.reciterNo,
      required this.reciterName,
      required this.isBookmarked,
      required this.bookmarkTap,
      required this.isSelected,
      required this.selected,
      required this.server})
      : super(key: key);

  @override
  State<EachReciterWidget> createState() => _EachReciterWidgetState();
}

class _EachReciterWidgetState extends State<EachReciterWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onDoubleTap: widget.bookmarkTap as void Function()?,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: widget.isSelected ? theme.primaryColor : theme.canvasColor,
            ),
            child: InkWell(
              onTap: widget.selected as void Function()?,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.reciterName,
                    style: theme.textTheme.headline6,
                  ),
                  InkWell(
                    onTap: widget.bookmarkTap as void Function()?,
                    child: Icon(
                      widget.isBookmarked ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      color: widget.isSelected ? theme.cardColor : theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EachTextSurahWidget extends StatelessWidget {
  final String chapterNo;
  final String chapterNameEn;
  final String chapterNameAr;
  final String chapterNametranslation;
  final String chapterType;
  final String chapterAyats;
  final bool isFavourite;

  final Function tap;
  final Function likeButton;

  const EachTextSurahWidget({
    Key? key,
    required this.chapterNo,
    required this.chapterNameEn,
    required this.chapterNameAr,
    required this.chapterNametranslation,
    required this.chapterType,
    required this.chapterAyats,
    required this.isFavourite,
    required this.tap,
    required this.likeButton,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: tap as void Function(),
      onDoubleTap: likeButton as void Function(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DecorationBorderWidget(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${int.parse(chapterNo)}. $chapterNameEn',
                        style: theme.textTheme.titleLarge?.copyWith(
                          height: 1.2,
                        ),
                      ),
                      Text(
                        '$chapterType - $chapterAyats Ayats',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.primaryColorLight),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: likeButton as void Function()?,
                    child: Icon(
                      isFavourite ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                      size: 35.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EachTextTranslationWidget extends StatelessWidget {
  final String translationNo;
  final String translationNameEn;
  final String translationNameL;
  final String type;

  final bool isBookmarked;
  final Function bookmarkTap;
  final bool isSelected;
  final bool isDownloading;
  final Function selectedTap;

  const EachTextTranslationWidget({
    Key? key,
    required this.translationNo,
    required this.translationNameEn,
    required this.translationNameL,
    required this.type,
    required this.isBookmarked,
    required this.bookmarkTap,
    this.isDownloading = false,
    required this.isSelected,
    required this.selectedTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        DecorationBorderWidget(
          child: InkWell(
            onDoubleTap: bookmarkTap as void Function()?,
            child: Column(
              children: [
                ListTile(
                  leading: CounterWidget(count: int.parse(translationNo)),
                  title: Text(
                    translationNameEn,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  trailing: Column(
                    children: [
                      Flexible(
                        flex: 3,
                        child: ElevatedButton(
                          style: theme.elevatedButtonTheme.style?.copyWith(
                            backgroundColor: MaterialStateProperty.all(
                              isSelected ? theme.primaryColor : theme.canvasColor, //Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: selectedTap as void Function()?,
                          child: Text(
                            isDownloading
                                ? AppLocalizations.of(context)!.downloading
                                : isSelected
                                    ? AppLocalizations.of(context)!.selected
                                    : AppLocalizations.of(context)!.select,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          onTap: bookmarkTap as void Function()?,
                          child: Icon(
                            isBookmarked ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '$translationNameL\n$type',
                    style: theme.textTheme.subtitle2!.copyWith(
                      color: theme.primaryColorLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

WidgetSpan counter(int i) {
  return WidgetSpan(
    child: Padding(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 8.0,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
              child: CustomPaint(
            size: Size(45, (45 * 1).toDouble()),
            painter: CounterFrame(),
          )),
          Positioned(
            left: i < 10
                ? 18.0
                : i < 100
                    ? 14.0
                    : 10.0,
            top: 6.0,
            width: 45.0,
            height: 45.0,
            child: Text(arabicNumeric(i + 1),
                softWrap: true,
                style: const TextStyle(
                  fontSize: 20.0,
                )),
          ),
        ],
      ),
    ),
  );
}

WidgetSpan stringCounter(int i, Key key, Function onVisibilityChanged) {
  return WidgetSpan(
    child: VisibilityDetector(
      onVisibilityChanged: (VisibilityInfo info) {
        onVisibilityChanged();
      },
      key: key,
      child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            bottom: 8.0,
          ),
          child: Text(
            '﴾${arabicNumeric(i + 1)}﴿',
            style: TextStyle(fontSize: UC.uv.selectedArabicFontSize),
          )),
    ),
  );
}

Widget justCount(int i) {
  return Padding(
    padding: const EdgeInsets.only(
      left: 8.0,
      right: 8.0,
      bottom: 8.0,
    ),
    child: Text(
      '﴾${arabicNumeric(i + 1)}﴿',
      style: const TextStyle(
        fontSize: 30.0,
      ),
    ),
  );
}

class CounterWidget extends StatelessWidget {
  final int count;
  final bool isReciting;
  const CounterWidget({Key? key, required this.count, this.isReciting = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      count.toString(),
      softWrap: true,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isReciting ? theme.primaryColor : theme.textTheme.bodyText1?.color,
      ),
    );
  }
}

class TitleWidget extends StatelessWidget {
  final String name;

  const TitleWidget({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.decoration),
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          child: AutoSizeText(
            name,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
    );
  }
}

class AdvantageItemWidget extends StatelessWidget {
  final String image;
  final String text;
  const AdvantageItemWidget({
    Key? key,
    required this.image,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        QuranIcons(width: 38, height: 38, assetName: image),
        const SizedBox(width: 15),
        RobotoRegular14(title: text),
      ],
    );
  }
}

// ignore: must_be_immutable
class FreeTrialWidget extends StatefulWidget {
  final ThemeData theme;
  final Size size;
  final String title;
  final String priceString;
  final Package packages;
  final int index;
  bool isChosen;

  FreeTrialWidget({
    Key? key,
    required this.theme,
    required this.size,
    required this.title,
    required this.priceString,
    required this.isChosen,
    required this.packages,
    required this.index,
  }) : super(key: key);

  @override
  State<FreeTrialWidget> createState() => _FreeTrialWidgetState();
}

class _FreeTrialWidgetState extends State<FreeTrialWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          color: !widget.isChosen ? widget.theme.focusColor : AppColors.darkGreenWithOpacity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!widget.isChosen)
                  Opacity(
                    opacity: 0.4,
                    child: SizedBox(
                      width: 70,
                      child: RobotoSemiBold13(
                        title: widget.title,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 70,
                    child: RobotoSemiBold13(
                      title: widget.title,
                    ),
                  ),
                const SizedBox(width: 10),
                if (!widget.isChosen)
                  const SizedBox.shrink()
                else
                  const QuranIcons(
                    width: 24,
                    height: 24,
                    assetName: AppAssets.check,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!widget.isChosen)
              Opacity(
                opacity: 0.7,
                child: Container(
                  height: 1,
                  width: widget.size.width / 3.9,
                  color: AppColors.whiteWithOpacity,
                ),
              )
            else
              Container(
                height: 1,
                width: widget.size.width / 3.9,
                color: AppColors.whiteWithOpacity,
              ),
            const SizedBox(height: 10),
            if (!widget.isChosen)
              Opacity(
                opacity: 0.7,
                child: RobotoRegular11(
                    title: widget.index == 0
                        ? '${widget.priceString}/${AppLocalizations.of(context)!.year}'
                        : '${widget.priceString}/${AppLocalizations.of(context)!.month}'),
              )
            else
              RobotoRegular11(
                  title: widget.index == 0
                      ? '${widget.priceString}/${AppLocalizations.of(context)!.year}'
                      : '${widget.priceString}/${AppLocalizations.of(context)!.month}'),
          ],
        ),
      ),
    );
  }
}

class ContinueButtonWidget extends StatelessWidget {
  final Size size;
  final ThemeData theme;
  final ValueChanged<List<Package>> onClickedPackage;
  final List<Package> package;
  final int? index;

  const ContinueButtonWidget({
    Key? key,
    required this.size,
    required this.theme,
    required this.onClickedPackage,
    required this.package,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: () => onClickedPackage(package),
        child: Container(
          height: 62,
          width: size.width,
          color: theme.cardColor,
          child: Row(
            children: [
              const SizedBox(width: 30),
              Text(
                AppLocalizations.of(context)!.continueButton,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.play_arrow_rounded,
                size: 24,
              ),
              const SizedBox(width: 30),
            ],
          ),
        ),
      ),
    );
  }
}
