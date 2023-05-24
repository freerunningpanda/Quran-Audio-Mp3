import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/audiostate.dart';
import '../screens/audioquran.dart';
import '../screens/res/app_colors.dart';
import 'control_buttons.dart';

class PlayerClose extends ConsumerWidget {
  final String image = 'https://cdn.pixabay.com/photo/2022/03/27/03/16/islamic-7093979_960_720.jpg';

  const PlayerClose({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, ref) {
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    final _ = ref.watch(audioQuranProvider);
    final audioState = ref.watch(audioStateProvider);
    return Container(
      height: orientation == Orientation.portrait ? size.height / 6.0 : size.height / 3.5,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        children: [
          const _Fringe(),
          ControlButtons(audioState: audioState),
          _SurahTitle(audioState: audioState),
          const Expanded(
            child: SizedBox.shrink(),
          ),
          _ProgressIndicatorWidget(audioState: audioState),
        ],
      ),
    );
  }
}

class _ProgressIndicatorWidget extends StatelessWidget {
  final AudioManager audioState;

  const _ProgressIndicatorWidget({
    Key? key,
    required this.audioState,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: (audioState.currentDuration?.inSeconds ?? 0) / (audioState.totalDuration?.inSeconds ?? 1),
      color: AppColors.yellow,
      backgroundColor: AppColors.yellow.withOpacity(0.3),
    );
  }
}

class _SurahTitle extends StatelessWidget {
  final AudioManager audioState;

  const _SurahTitle({
    Key? key,
    required this.audioState,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Text(
      '${audioState.currentRecitingSurah?.number ?? ''}. ${audioState.currentRecitingSurah?.englishName ?? ''}',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.white),
    );
  }
}



class _Fringe extends StatelessWidget {
  const _Fringe({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          top: 5.0,
        ),
        width: 50.0,
        height: 3.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: AppColors.white,
        ),
      ),
    );
  }
}