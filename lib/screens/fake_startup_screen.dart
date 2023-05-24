// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/banner_provider.dart';
import '../provider/firebase_analytics_provider.dart';
import '../provider/interstitial_provider.dart';
import 'home.dart';
import 'res/app_assets.dart';

// Фейковый экран загрузки приложения (для free версии)
// Используется для имитации загрузки при каждом запуске приложения
class FakeStartupScreen extends StatefulWidget {
  static const String id = 'fakeStartupScreen';
  const FakeStartupScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<FakeStartupScreen> createState() => _FakeStartupScreenState();
}

class _FakeStartupScreenState extends State<FakeStartupScreen> {
  @override
  void initState() {
    context.read<FirebaseAnalyticsProvider>().currentScreen(screenName: HomePre.id);
    context.read<FirebaseAnalyticsProvider>().sendAnalytics();
    goToMainScreen();
    super.initState();
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
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.isLoading,
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

  void goToMainScreen() {
    final isAdLoad = context.read<InterstitialProvider>().isAdLoad; // Если true значит интер загружен
    Future.delayed(
      const Duration(seconds: 3),
      () {
        // Если интер загружен, то отображаем его перед переходом на главную
        if (isAdLoad) {
          context.read<InterstitialProvider>().showInterstitialAd();
          Navigator.pushReplacementNamed(context, HomePre.id);
          // Иначе переходим на главную без показа интера
        } else {
          Navigator.pushReplacementNamed(context, HomePre.id);
        }
      },
    );
  }
}
