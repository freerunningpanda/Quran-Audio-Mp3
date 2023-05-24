import 'package:flutter/material.dart';

import '../screens/res/app_typography.dart';

class RatingActionButton extends StatelessWidget {
  final String title;
  static const String id = 'onboardingScreen';
  final VoidCallback onTap;

  const RatingActionButton({
    Key? key,
    required this.onTap,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(
          height: 62,
          width: width - 66,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RobotoSemiBold18(
                title: title,
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
              onTap: onTap,
            ),
          ),
        )
      ],
    );
  }
}
