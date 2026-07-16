// Wraps: purchases_flutter 10.4.1 (RevenueCat), verified on pub.dev
// 2026-07-13. Two changes matter since older majors: purchase methods return a
// PurchaseResult (customerInfo plus storeTransaction) instead of CustomerInfo,
// and version 10 raised the Android floor to API 23. One entitlement, "pro",
// drives every gated feature. Docs:
// https://www.revenuecat.com/docs/getting-started/configuring-sdk

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants.dart';
import '../core/result.dart';

/// Behind an interface so the UI reads a single boolean and tests can fake Pro.
abstract interface class BillingService {
  Future<void> init(String publicSdkKey);
  Future<bool> isPro();
  Future<Result<bool>> purchasePro();
  Future<Result<bool>> restore();

  /// Fires with the current Pro state whenever the store pushes an update,
  /// for example a pending Play purchase completing in the background.
  void onProChanged(void Function(bool isPro) listener);
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
  void onProChanged(void Function(bool isPro) listener) {
    Purchases.addCustomerInfoUpdateListener((info) {
      listener(info.entitlements.active.containsKey(Entitlements.pro));
    });
  }

  @override
  Future<Result<bool>> purchasePro() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages;
      if (packages == null || packages.isEmpty) {
        return const Err('No subscription is available right now.');
      }
      final result =
          await Purchases.purchase(PurchaseParams.package(packages.first));
      final pro =
          result.customerInfo.entitlements.active.containsKey(Entitlements.pro);
      return Ok(pro);
    } on PlatformException catch (e) {
      // Backing out of the Play sheet is a decision, not a failure, and must
      // not surface as an error snackbar.
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return const Ok(false);
      }
      return Err('The purchase did not complete.', cause: e);
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

/// Used while the RevenueCat keys are empty, which is the normal state during
/// development. Everything reads as free and purchase attempts explain why.
class FreeBillingService implements BillingService {
  @override
  Future<void> init(String publicSdkKey) async {}

  @override
  Future<bool> isPro() async => false;

  @override
  void onProChanged(void Function(bool isPro) listener) {}

  @override
  Future<Result<bool>> purchasePro() async =>
      const Err('Purchases are not available in this build.');

  @override
  Future<Result<bool>> restore() async =>
      const Err('Purchases are not available in this build.');
}
