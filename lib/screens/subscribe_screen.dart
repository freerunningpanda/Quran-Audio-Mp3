import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../provider/revenue_cat_provider.dart';
import '../utils/fastfunctions.dart';
import '../utils/rate_app_preferences.dart';
import '../widgets/quran_icons.dart';
import '../widgets/reuseablewidgets.dart';
import 'onboarding_screen.dart';
import 'res/app_assets.dart';
import 'res/app_typography.dart';

class SubscribeScreen extends StatefulWidget {
  final bool? isMainPage;
  static const String id = "subscribe_screen";
  final ValueChanged<Package> onClickedPackage;

  const SubscribeScreen({
    Key? key,
    this.isMainPage,
    required this.onClickedPackage,
  }) : super(key: key);

  @override
  State<SubscribeScreen> createState() => SubscribeScreenState();
}

class SubscribeScreenState extends State<SubscribeScreen> {
  int selectedIndex = 1;
  bool storeVisited = RateAppPreferences.getStoreVisitValue();

  @override
  Widget build(BuildContext context) {
    context.watch<RevenueCatProvider>();
    final packages = context.read<RevenueCatProvider>().packages;
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Opacity(
                  opacity: 0.25,
                  child: InkWell(
                    // Если данная страница загрузилась на главной (при старте приложения(free версия))
                    // То после возврата назад, показать экран оценки (если не было визита в стор)
                    // Если был визит в стор, но версия (free), то просто возврат на предыдущий экран
                    // Иначе, просто вернётся назад c данной страницы
                    onTap: widget.isMainPage ?? false
                        ? () {
                            if (!storeVisited) {
                              Navigator.pop(context);
                              showRatingWindow(context);
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        : () => Navigator.pop(context),
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
          SizedBox(
            height: size.height / 1.2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 17.0),
                  child: FutureBuilder(
                      future: context.read<RevenueCatProvider>().fetchOffer(context),
                      builder: (_, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List?.generate(
                              2,
                              (index) {
                                index;
                                return Stack(
                                  children: [
                                    FreeTrialWidget(
                                      priceString: index == 0
                                          ? packages[index].storeProduct.priceString
                                          : packages[index].storeProduct.priceString,
                                      title: index == 0
                                          ? AppLocalizations.of(context)!.sevenDays
                                          : AppLocalizations.of(context)!.threeDays,
                                      size: size,
                                      theme: theme,
                                      isChosen: selectedIndex == index ? true : false,
                                      index: index,
                                      packages: packages[index],
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
                  padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 50.0),
                  child: Text(
                    AppLocalizations.of(context)!.subscribeTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.cardColor,
                      height: 1.25,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 33.0),
                  child: ContinueButtonWidget(
                    size: size,
                    theme: theme,
                    onClickedPackage: (package) async {
                      if (isGlobalYearly) {
                        debugPrint('Package Yearly: >>>> ${packages[0]}');
                        await purchasePackage(package[0], context);
                      } else {
                        debugPrint('Package Monthly: >>>> ${packages[1]}');
                        await purchasePackage(package[1], context);
                      }

                      // ignore: use_build_context_synchronously
                      // Navigator.pop(context);
                    },
                    package: packages,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38),
                  child: RobotoRegular11(title: AppLocalizations.of(context)!.subscribeDescription),
                ),
                // const SizedBox(height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
