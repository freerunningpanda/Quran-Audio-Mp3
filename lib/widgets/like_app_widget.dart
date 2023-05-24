import 'package:flutter/material.dart';

import 'package:store_redirect/store_redirect.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/res/app_assets.dart';
import '../screens/res/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/res/app_typography.dart';
import '../utils/rate_app_preferences.dart';
import 'rating_action_btn.dart';
import 'review_app_widget.dart';

bool isFirstOpening = true;
bool storeVisited = false;
var rating = 4;

class LikeAppWidget extends StatefulWidget {
  const LikeAppWidget({Key? key}) : super(key: key);

  @override
  State<LikeAppWidget> createState() => _LikeAppWidgetState();
}

class _LikeAppWidgetState extends State<LikeAppWidget> {
  var _isYesButtonPressed = false;
  int? sentRating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height / 1.5,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50.0),
          topRight: Radius.circular(50.0),
        ),
        color: theme.cardColor,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 27,
            left: 30,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.close_rounded,
                size: 24,
                color: theme.shadowColor.withOpacity(0.5),
              ),
            ),
          ),
          if (rating == 1 || rating == 2 || rating == 3)
            Positioned(
              top: -90,
              child: Image.asset(
                AppAssets.ratingScreen2,
                scale: 4,
              ),
            )
          else if (rating == 4)
            Positioned(
              top: -90,
              child: Image.asset(
                AppAssets.ratingScreen1,
                scale: 4,
              ),
            )
          else if (rating == 5)
            Positioned(
              top: -90,
              child: Image.asset(
                AppAssets.ratingScreen3,
                scale: 4,
              ),
            ),
          Positioned(
            bottom: size.height / 12,
            child: Visibility(
              visible: !_isYesButtonPressed,
              replacement: Column(
                children: [
                  SizedBox(
                    width: size.width / 1.5,
                    child: RobotoSemiBold22(title: AppLocalizations.of(context)!.fiveStars),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Stack(
                          children: [
                            if (index < rating)
                              SvgPicture.asset(
                                AppAssets.activeStar,
                                width: 42,
                                height: 42,
                              )
                            else
                              SvgPicture.asset(
                                AppAssets.innactiveStar,
                                width: 42,
                                height: 42,
                              ),
                            Positioned.fill(
                                child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  setState(
                                    () {
                                      rating = index + 1;
                                    },
                                  );
                                },
                              ),
                            ))
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 43),
                  RatingActionButton(
                    title: AppLocalizations.of(context)!.rateApp,
                    onTap: () async {
                      if (rating < 5) {
                        setState(() {
                          _isYesButtonPressed = false;
                        });
                        sentRating = rating;
                        _showReviewWindow(context);
                      } else {
                        debugPrint('going to store...');
                        StoreRedirect.redirect(
                            androidAppId: 'com.simpleapp.quranapp', iOSAppId: 'com.simpleapp.quranapp');
                        await RateAppPreferences.setStoreVisitValue(storeVisited = true);
                      }
                    },
                  ),
                ],
              ),
              child: _actionButtons(context, size, theme),
            ),
          ),
        ],
      ),
    );
  }

  Column _actionButtons(BuildContext context, Size size, ThemeData theme) {
    return Column(
      children: [
        RobotoRegular18(title: AppLocalizations.of(context)!.impressions),
        const SizedBox(height: 10.0),
        RobotoSemiBold22(title: AppLocalizations.of(context)!.likeTheApp),
        const SizedBox(height: 25.0),
        _yesButton(size, theme),
        const SizedBox(height: 18.0),
        _noButton(size, theme),
      ],
    );
  }

  Stack _yesButton(Size size, ThemeData theme) {
    return Stack(
      children: [
        Container(
          height: 62,
          width: size.width - 66,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.primaryColor,
              width: 2,
            ),
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RobotoSemiBold18(
                title: AppLocalizations.of(context)!.yes,
                isYesOrDone: true,
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(30.0),
              onTap: () {
                setState(() {
                  rating = 5;
                  _isYesButtonPressed = true;
                });
              },
            ),
          ),
        )
      ],
    );
  }

  Stack _noButton(Size size, ThemeData theme) {
    return Stack(
      children: [
        Container(
          height: 62,
          width: size.width - 66,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.primaryColor,
              width: 2,
            ),
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RobotoSemiBold18(
                title: AppLocalizations.of(context)!.no,
                isYesOrDone: false,
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(30.0),
              onTap: () => _showReviewWindow(context),
            ),
          ),
        )
      ],
    );
  }

  void _showReviewWindow(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewAppWidget(
          sentRating: sentRating,
        ),
      ),
    );
  }
}
