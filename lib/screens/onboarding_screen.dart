import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart' as provider;

import 'package:quran/screens/res/app_colors.dart';
import 'package:quran/screens/res/app_typography.dart';
import 'package:quran/widgets/quran_icons.dart';

import '../provider/banner_provider.dart';
import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import '../utils/constants.dart';
import '../utils/fastfunctions.dart';
import '../widgets/reuseablewidgets.dart';
import 'home.dart';
import 'res/app_assets.dart';

bool isGlobalYearly = false;

class OnboardingScreen extends StatefulWidget {
  static const String id = 'onboardingScreen';
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _currentIndex = 0;

  @override
  void initState() {
    context.read<RevenueCatProvider>().fetchOffer(context);
    context.read<InterstitialProvider>().createInterstitialAd();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final packages = context.read<RevenueCatProvider>().packages;

    context.watch<RevenueCatProvider>();

    final pages = <Widget>[
      _OnboardingScreenWidget(
        title: AppLocalizations.of(context)!.onBoardingTitle_1,
        image: AppAssets.onboardingImageFirst,
        theme: theme,
        controller: _controller,
      ),
      _OnboardingScreenWidget(
        title: AppLocalizations.of(context)!.onBoardingTitle_2,
        image: AppAssets.onboardingImageSecond,
        theme: theme,
        controller: _controller,
      ),
      _OnboardingScreenWidget(
        title: AppLocalizations.of(context)!.onBoardingTitle_3,
        image: AppAssets.onboardingImageThird,
        theme: theme,
        controller: _controller,
      ),
      _SubscribeScreenWidget(
        title: AppLocalizations.of(context)!.subscribeTitle,
        theme: theme,
        controller: _controller,
        packages: packages,
        onClickedPackage: (package) async {
          await purchasePackage(package, context);

          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        },
      ),
    ];

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (value) {
                  setState(() => _currentIndex = value);
                  _controller.animateToPage(
                    _currentIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.linear,
                  );
                },
                controller: _controller,
                children: pages,
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: 4,
              onDotClicked: (index) {
                setState(() => _currentIndex = index);
                _controller.animateToPage(
                  _currentIndex,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.linear,
                );
              },
              effect: ExpandingDotsEffect(
                activeDotColor: theme.cardColor,
                dotColor: AppColors.whiteWithOpacity,
                dotWidth: 10,
                dotHeight: 10,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 33.0),
              child: ContinueButtonWidget(
                index: _currentIndex,
                size: size,
                theme: theme,
                onClickedPackage: (package) async {
                  if (_currentIndex < 3) {
                    debugPrint('pressed');
                    setState(() => _currentIndex);
                    _controller.animateToPage(
                      _currentIndex + 1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.linear,
                    );
                  } else {
                    if (isGlobalYearly) {
                      debugPrint('Package Yearly: >>>> ${packages[0]}');
                      await purchasePackage(package[0], context);
                    } else {
                      debugPrint('Package Monthly: >>>> ${packages[1]}');
                      await purchasePackage(package[1], context);
                    }
                  }
                  // ignore: use_build_context_synchronously
                  // Navigator.pop(context);
                },
                package: packages,
              ),
            ),
            const SizedBox(height: 30),
            if (_currentIndex != 3)
              const _AgreementButtonsWidget()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: RobotoRegular11(title: AppLocalizations.of(context)!.subscribeDescription),
              ),
            if (_currentIndex != 3) SizedBox(height: size.height / 8) else SizedBox(height: size.height / 10.95),
          ],
        ),
      ),
    );
  }
}

class _AgreementButtonsWidget extends StatelessWidget {
  const _AgreementButtonsWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // TO DO: Privacy policy
        InkWell(
          onTap: () => lauchUrl(termsOfUse),
          child: RobotoSemiBold14(title: AppLocalizations.of(context)!.termsOfUse),
        ),
        InkWell(
          onTap: () => lauchUrl(privatePolicy),
          child: RobotoSemiBold14(title: AppLocalizations.of(context)!.privacyPolicy),
        ),
      ],
    );
  }
}

class _OnboardingScreenWidget extends StatelessWidget {
  final String title;
  final String image;
  final ThemeData theme;
  final PageController controller;

  const _OnboardingScreenWidget({
    Key? key,
    required this.title,
    required this.image,
    required this.theme,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<BannerProvider>();

    return Column(
      children: [
        const SizedBox(height: 45),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Opacity(
                opacity: 0.25,
                child: InkWell(
                  onTap: () {
                    context.read<InterstitialProvider>().showInterstitialAd();
                    Navigator.of(context).pushReplacementNamed(HomePre.id);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: theme.cardColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Image.asset(image),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 33),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.cardColor, height: 1.25, fontSize: 23, fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubscribeScreenWidget extends StatefulWidget {
  final String title;
  final ThemeData theme;
  final PageController controller;
  final ValueChanged<Package> onClickedPackage;
  final List<Package> packages;

  const _SubscribeScreenWidget({
    Key? key,
    required this.title,
    required this.theme,
    required this.controller,
    required this.onClickedPackage,
    required this.packages,
  }) : super(key: key);

  @override
  State<_SubscribeScreenWidget> createState() => _SubscribeScreenWidgetState();
}

class _SubscribeScreenWidgetState extends State<_SubscribeScreenWidget> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    context.watch<RevenueCatProvider>();
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Opacity(
                opacity: 0.25,
                child: InkWell(
                  onTap: () {
                    context.read<InterstitialProvider>().showInterstitialAd();
                    Navigator.of(context).pushReplacementNamed(HomePre.id);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: widget.theme.cardColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 17.0),
              child: FutureBuilder(
                  future: context.read<RevenueCatProvider>().fetchOffer(context),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          2,
                          (index) {
                            index;
                            return Stack(
                              children: [
                                FreeTrialWidget(
                                  priceString: index == 0
                                          ? widget.packages[index].storeProduct.priceString
                                          : widget.packages[index].storeProduct.priceString,
                                  title: index == 0
                                      ? AppLocalizations.of(context)!.sevenDays
                                      : AppLocalizations.of(context)!.threeDays,
                                  size: size,
                                  theme: widget.theme,
                                  isChosen: selectedIndex == index ? true : false,
                                  index: index,
                                  packages: widget.packages[index],
                                ),
                                Positioned.fill(
                                  left: 12,
                                  right: 12,
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () {
                                        setState(() {
                                          selectedIndex = index;
                                          if (selectedIndex == 0) {
                                            isGlobalYearly = true;
                                          } else {
                                            isGlobalYearly = false;
                                          }
                                        });
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (selectedIndex == index)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: const [
                                                QuranIcons(
                                                  width: 18,
                                                  height: 18,
                                                  assetName: AppAssets.glare,
                                                ),
                                                SizedBox(width: 3),
                                              ],
                                            )
                                          else
                                            const SizedBox.shrink(),
                                          if (selectedIndex == index)
                                            Column(
                                              children: [
                                                const SizedBox(height: 30),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: const [
                                                    QuranIcons(
                                                      width: 18,
                                                      height: 18,
                                                      assetName: AppAssets.glare,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          const SizedBox.shrink(),
                                          if (selectedIndex == index)
                                            Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: const [
                                                    QuranIcons(
                                                      width: 18,
                                                      height: 18,
                                                      assetName: AppAssets.glare,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          const SizedBox.shrink(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    } else {
                      return SizedBox(
                        height: size.height / 7.6,
                      );
                    }
                  }),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width / 4.5),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AdvantageItemWidget(
                      image: AppAssets.hand,
                      text: AppLocalizations.of(context)!.advertisement,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AdvantageItemWidget(
                      image: AppAssets.infinity,
                      text: AppLocalizations.of(context)!.features,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AdvantageItemWidget(
                      image: AppAssets.book,
                      text: AppLocalizations.of(context)!.support,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 16.0),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.theme.cardColor,
                  height: 1.25,
                  fontSize: 20,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
