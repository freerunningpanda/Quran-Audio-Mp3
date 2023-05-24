import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/audiostate.dart';
import '../screens/audioquran.dart';
import '../screens/res/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'control_buttons.dart';

class PlayerOpen extends ConsumerWidget {
  final String bgImage =
      'https://krot.info/uploads/posts/2022-02/thumbs/1645045660_54-krot-info-p-vostochnie-foni-54.jpg';

  PlayerOpen({super.key});

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context, ref) {
    final _ = ref.watch(audioQuranProvider);
    final audioState = ref.watch(audioStateProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation == Orientation.portrait;

    return SafeArea(
      child: Scrollbar(
        radius: const Radius.circular(12.0),
        thickness: 3,
        thumbVisibility: true,
        controller: scrollController,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.green,
                AppColors.black,
              ],
            ),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              _TitleWidget(theme: theme, audioState: audioState),
              _CoverWidget(
                orientation: orientation,
                size: size,
                bgImage: bgImage,
                audioState: audioState,
              ),
              Column(
                children: [
                  _SliderWidget(audioState: audioState),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: ControlButtons(audioState: audioState),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderWidget extends StatelessWidget {
  final AudioManager audioState;

  const _SliderWidget({
    Key? key,
    required this.audioState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Slider(
          min: 0,
          max: audioState.totalDuration?.inSeconds.toDouble() ?? 1.0,
          value: audioState.currentDuration?.inSeconds.toDouble() ?? 0.0,
          onChanged: (value) {
            audioState.player.seek(Duration(seconds: value.toInt()));
          },
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: AppColors.white,
        ),
        Positioned(
          left: 25,
          bottom: -15,
          child: Text(
            audioState.currentDuration?.durationText ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: 22,
          bottom: -15,
          child: Text(
            audioState.totalDuration?.durationText ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverWidget extends StatelessWidget {
  final bool orientation;
  final Size size;
  final String bgImage;
  final AudioManager audioState;

  const _CoverWidget({
    Key? key,
    required this.orientation,
    required this.size,
    required this.bgImage,
    required this.audioState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: orientation ? size.width / 1.3 : size.width / 3.0,
                height: orientation ? size.height / 2.3 : size.height / 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  shape: BoxShape.rectangle,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(bgImage),
                  ),
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.surahNo} ${audioState.currentRecitingSurah?.number ?? ''}',
                        style: Theme.of(context).textTheme.headline4!.copyWith(
                              color: AppColors.white,
                            ),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.ayahs}. ${audioState.currentRecitingSurah?.numberOfAyahs ?? ''}',
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: AppColors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    '${audioState.currentRecitingSurah?.number ?? ''}. ${audioState.currentRecitingSurah?.englishName ?? AppLocalizations.of(context)!.starting}',
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          color: AppColors.white,
                        ),
                  ),
                  Positioned(
                    bottom: -15,
                    child: Text(
                      audioState.currentRecitingSurah?.revelationType ?? '',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: AppColors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleWidget extends StatelessWidget {
  final ThemeData theme;
  final AudioManager audioState;

  const _TitleWidget({
    Key? key,
    required this.theme,
    required this.audioState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.white,
                  size: 40.0,
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.recitingSurahs,
              style: theme.textTheme.headline5?.copyWith(
                color: AppColors.white,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              color: AppColors.transparent,
            ),
          ],
        ),
        Text(
          audioState.currentRecitingAlbum ?? '',
          style: theme.textTheme.subtitle1?.copyWith(
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

extension DurationIntoTexts on Duration {
  String get durationText {
    final int hours = inHours;
    final int minutes = inMinutes - hours * 60;
    final int seconds = inSeconds - hours * 60 * 60 - minutes * 60;
    return '$hours:$minutes:$seconds';
  }
}

extension DurationIntoText on Duration {
  String get durationTexts {
    final int hours = inHours;
    final int minutes = inMinutes - hours * 60;
    final int seconds = inSeconds - hours * 60 * 60 - minutes * 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
