// The entitlement bootstrap has to survive the real world: the store can be
// offline on first launch, and a pending Play purchase can complete long
// after the purchase sheet closed. Neither may strand the user.

import 'package:docscan/core/result.dart';
import 'package:docscan/services/billing_service.dart';
import 'package:docscan/state/billing_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingBillingService implements BillingService {
  @override
  Future<void> init(String publicSdkKey) async {}

  @override
  Future<bool> isPro() async => throw Exception('offline');

  @override
  void onProChanged(void Function(bool isPro) listener) {}

  @override
  Future<Result<bool>> purchasePro() async =>
      const Err('Purchases are not available in this build.');

  @override
  Future<Result<bool>> restore() async =>
      const Err('Purchases are not available in this build.');
}

class _PushingBillingService implements BillingService {
  void Function(bool isPro)? listener;

  @override
  Future<void> init(String publicSdkKey) async {}

  @override
  Future<bool> isPro() async => false;

  @override
  void onProChanged(void Function(bool isPro) l) => listener = l;

  @override
  Future<Result<bool>> purchasePro() async =>
      const Err('Purchases are not available in this build.');

  @override
  Future<Result<bool>> restore() async =>
      const Err('Purchases are not available in this build.');
}

void main() {
  test('a failing entitlement check leaves the user free, never stuck',
      () async {
    final container = ProviderContainer(overrides: [
      billingServiceProvider.overrideWith((ref) => _ThrowingBillingService()),
    ]);
    addTearDown(container.dispose);

    expect(container.read(billingProvider), isFalse);
    // ready must complete even though the store threw; startup and the scan
    // flow wait on it.
    await container.read(billingProvider.notifier).ready;
    expect(container.read(billingProvider), isFalse);
  });

  test('a store push, like a pending purchase completing, unlocks Pro',
      () async {
    final billing = _PushingBillingService();
    final container = ProviderContainer(overrides: [
      billingServiceProvider.overrideWith((ref) => billing),
    ]);
    addTearDown(container.dispose);

    await container.read(billingProvider.notifier).ready;
    expect(container.read(billingProvider), isFalse);

    billing.listener!(true);
    expect(container.read(billingProvider), isTrue);
  });
}
