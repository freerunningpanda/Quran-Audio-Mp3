import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/audiostate.dart';
import '../screens/audioquran.dart';
import '../screens/res/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ControlButtons extends StatelessWidget {
  final AudioManager audioState;

  const ControlButtons({
    Key? key,
    required this.audioState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Builder(
          builder: (context) {
            IconData iconData = Icons.play_arrow;
            AudioPlayer audioPlayer = audioState.player;

            if (audioPlayer.playing) {
              iconData = Icons.pause;
            }

            return Row(
              children: [
                _GoToPreviousButton(player: audioPlayer),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: _PlayButton(player: audioPlayer, iconData: iconData),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: _GoToNextButton(audioPlayer: audioPlayer),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GoToNextButton extends StatelessWidget {
  const _GoToNextButton({
    Key? key,
    required this.audioPlayer,
  }) : super(key: key);

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        audioPlayer.hasNext ? audioPlayer.seekToNext() : null;
      },
      child: SizedBox(
        width: 50.0,
        height: 50.0,
        child: Stack(
          children: [
            const Positioned(
              child: Card(
                shape: CircleBorder(),
              ),
            ),
            Positioned(
              left: 5.0,
              top: 5.0,
              child: SizedBox(
                width: 45.0,
                height: 45.0,
                child: Card(
                  shape: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      CupertinoIcons.forward_end_fill,
                      size: 15.0,
                      color: audioPlayer.hasNext ? Theme.of(context).primaryColor : AppColors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final AudioPlayer player;
  final IconData iconData;

  const _PlayButton({
    Key? key,
    required this.player,
    required this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (player.playing) {
          player.pause();
        } else {
          try {
            if (player.duration?.inSeconds == 0) {
              await player.load();
            }
            await player.play();

          } on PlayerException {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.wifi_slash,
                      color: AppColors.white,
                    ),
                    Text(
                      AppLocalizations.of(context)!.requireInternet,
                      style: const TextStyle(
                        color: AppColors.white,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
                backgroundColor: AppColors.red,
              ),
            );
          } catch (e) {
            Navigator.pushNamed(context, QuranAudio.id);
          }
        }
      },
      child: SizedBox(
        width: 70.0,
        height: 70.0,
        child: Stack(
          children: [
            const Positioned(
              child: Card(
                shape: CircleBorder(),
              ),
            ),
            Positioned(
              left: 8.0,
              top: 8.0,
              child: SizedBox(
                width: 55.0,
                height: 55.0,
                child: Card(
                  shape: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 40.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoToPreviousButton extends StatelessWidget {
  final AudioPlayer player;

  const _GoToPreviousButton({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        player.hasPrevious ? player.seekToPrevious() : null;
      },
      child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: Stack(
              children: [
                const Positioned(
                  child: Card(
                    shape: CircleBorder(),
                  ),
                ),
                Positioned(
                  left: 5.0,
                  top: 5.0,
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Card(
                      shape: const CircleBorder(),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.backward_end_fill,
                          size: 15.0,
                          color: player.hasPrevious ? Theme.of(context).primaryColor : AppColors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
