import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerProvider extends ChangeNotifier {
  BannerAd? bannerAd;
  bool bannerAdIsLoaded = false;

  AdManagerBannerAd? adManagerBannerAd;
  bool adManagerBannerAdIsLoaded = false;

  Future<void> init() {
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 
      // 'ca-app-pub-9288531620476063/2616165290',
          // test ids
          Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$BannerAd loaded.');
          bannerAdIsLoaded = true;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$BannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => debugPrint('$BannerAd onAdClosed.'),
      ),
      request: const AdRequest(),
    );
    return bannerAd!.load();
  }

  Future<void> initManagerBanner() {
    adManagerBannerAd = AdManagerBannerAd(
      adUnitId: '/6499/example/banner',
      request: const AdManagerAdRequest(nonPersonalizedAds: true),
      sizes: <AdSize>[AdSize.largeBanner],
      listener: AdManagerBannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$AdManagerBannerAd loaded.');
          adManagerBannerAdIsLoaded = true;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$AdManagerBannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('$AdManagerBannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => debugPrint('$AdManagerBannerAd onAdClosed.'),
      ),
    );
    return adManagerBannerAd!.load();
  }

  void disposeBanners() {
    bannerAd?.dispose();
    adManagerBannerAd?.dispose();
    notifyListeners();
  }
}
