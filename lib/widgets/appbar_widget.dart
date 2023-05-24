import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/screens/res/app_assets.dart';
import 'package:quran/screens/res/app_colors.dart';
import 'package:quran/widgets/quran_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';
import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import '../screens/res/app_strings.dart';
import '../utils/fastfunctions.dart';

class AppBarWidget extends StatelessWidget with PreferredSizeWidget {
  const AppBarWidget({
    Key? key,
    required this.c,
  }) : super(key: key);

  final Controller c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0.0,
      backgroundColor: Theme.of(context).canvasColor,
      centerTitle: true,
      automaticallyImplyLeading: false, //true,
      foregroundColor: const Color(0XFF29BB89),

      actions: [
        GestureDetector(
          onTap: () {
            final isSubActive = context.read<RevenueCatProvider>().isSubActive;
            if (!isSubActive) {
              showInterAtSixTime(context);
            }
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                title: Text(
                  AppLocalizations.of(context)!.changeTheme,
                  style: theme.textTheme.headline4?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                cancelButton: Material(
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: theme.textTheme.headline5,
                      ),
                    ),
                  ),
                ),
                actions: [
                  CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                      c.updateAppTheme(0);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.systemDefault,
                      style: theme.textTheme.headline6,
                    ),
                  ),
                  CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                      c.updateAppTheme(1);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.lightTheme,
                      style: theme.textTheme.headline6,
                    ),
                  ),
                  CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                      c.updateAppTheme(2);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.darkTheme,
                      style: theme.textTheme.headline6,
                    ),
                  ),
                ],
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.only(
              top: 15.0,
              right: 20.0,
              left: 20.0,
            ),
            child: QuranIcons(
              width: 24,
              height: 24,
              assetName: AppAssets.moon,
            ),
          ),
        ),
      ],

      title: const Text(
        AppStrings.quranApp,
        style: TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
