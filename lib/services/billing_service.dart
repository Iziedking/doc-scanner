// Wraps: purchases_flutter (RevenueCat). One entitlement, "pro", drives every
// gated feature. Verify the RevenueCat Flutter API and set up your products in
// the RevenueCat and Play Console dashboards. Docs:
// https://www.revenuecat.com/docs/getting-started/installation/flutter

import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants.dart';
import '../core/result.dart';

/// Behind an interface so the UI reads a single boolean and tests can fake Pro.
abstract interface class BillingService {
  Future<void> init(String publicSdkKey);
  Future<bool> isPro();
  Future<Result<bool>> purchasePro();
  Future<Result<bool>> restore();
}

class RevenueCatBillingService implements BillingService {
  @override
  Future<void> init(String publicSdkKey) async {
    await Purchases.configure(PurchasesConfiguration(publicSdkKey));
  }

  @override
  Future<bool> isPro() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(Entitlements.pro);
  }

  @override
  Future<Result<bool>> purchasePro() async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.first;
      if (pkg == null) {
        return const Err('No subscription is available right now.');
      }
      final info = await Purchases.purchasePackage(pkg);
      final pro = info.entitlements.active.containsKey(Entitlements.pro);
      return Ok(pro);
    } catch (e) {
      return Err('The purchase did not complete.', cause: e);
    }
  }

  @override
  Future<Result<bool>> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return Ok(info.entitlements.active.containsKey(Entitlements.pro));
    } catch (e) {
      return Err('Restore failed.', cause: e);
    }
  }
}
