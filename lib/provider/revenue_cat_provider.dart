import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:quran/utils/fastfunctions.dart';

class RevenueCatProvider extends ChangeNotifier {
  RevenueCatProvider() {
    init();
  }

  bool isSubActive = false;

  late List<Package> packages = [];

  Future init() async {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      getSubs();
    });
  }

  Future<bool> getSubs() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all['all_features'] != null) {
        if (customerInfo.entitlements.all['all_features']!.isActive) {
          isSubActive = true;
          return true;
        } else {
          isSubActive = false;
          return false;
        }
      }
    } on PlatformException catch (e) {
      debugPrint('$e');
    }
    return false;
  }

  Future fetchOffer(BuildContext context) async {
    final offerings = await fetchOffers();

    if (offerings.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Plans Found'),
        ),
      );
    } else {
      packages = offerings.map((offer) => offer.availablePackages).expand((pair) => pair).toList();
    }
  }

  // Future updatePurchaseStatus() async {
  //   final purchaserInfo = await Purchases.getCustomerInfo();

  //   final entitlements = purchaserInfo.entitlements.active.values.toList();
  //   _entitlement = entitlements.isEmpty ? Entitlement.free : Entitlement.noAdvert;
  //   notifyListeners();
  // }
}
