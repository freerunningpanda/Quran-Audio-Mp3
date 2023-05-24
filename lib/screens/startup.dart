// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:quran/utils/constants.dart';
import 'package:quran/utils/initialization.dart';
import 'package:quran/main.dart';
import 'package:quran/widgets/reuseablewidgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'onboarding_screen.dart';
import 'res/app_assets.dart';
import 'res/app_colors.dart';
import 'res/app_strings.dart';

class StartupScreen extends StatefulWidget {
  static const String id = 'startupScreen';
  const StartupScreen({Key? key}) : super(key: key);

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool tryAgain = false;
  String status = AppStrings.isLoading;
  firstStartUp() async {
    try {
      await Initialization().initializePrayers();
      await Initialization().initializeQuran();
      UC.hive.put(
        kInitializedVersion,
        kCurrentVersion,
      );
      UC.uv = UniversalVariables();
      Navigator.pushReplacementNamed(context, OnboardingScreen.id);
    } catch (e) {
      tryAgain = true;
      status = AppLocalizations.of(context)!.needInternet;
      setState(() {});
      showToast(context: context, content: Text(e.toString()), color: Colors.red);
    }
  }

  retry() {
    tryAgain = false;
    status = AppLocalizations.of(context)!.isLoading;
    setState(() {});
    firstStartUp();
  }

  @override
  void initState() {
    super.initState();
    // context.read<InterstitialProvider>().createInterstitialAd();
    firstStartUp();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(
              AppAssets.quranBackground,
            ),
          )),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                tryAgain
                    ? ElevatedButton(
                        onPressed: () {
                          retry();
                        },
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          foregroundColor: const MaterialStatePropertyAll<Color>(AppColors.red),
                        ),
                        child: Text(AppLocalizations.of(context)!.needInternet),
                      )
                    : const SizedBox(),
                Text(
                  status,
                  style: theme.textTheme.headline6?.copyWith(color: theme.cardColor),
                ),
                CircularProgressIndicator(
                  color: theme.cardColor,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
