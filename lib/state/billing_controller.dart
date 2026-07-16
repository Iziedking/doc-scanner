// Exposes one thing to the UI: is the user Pro. Everything gated reads this.
// Built on flutter_riverpod 3.3.2 Notifier, not the legacy StateNotifier.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../services/billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  throw UnimplementedError('Override in main() with the configured service.');
});

class BillingController extends Notifier<bool> {
  BillingService get _billing => ref.read(billingServiceProvider);

  late Future<void> _firstLoad;

  @override
  bool build() {
    _firstLoad = _load();
    // The store can flip the entitlement outside a foreground purchase, for
    // example when a pending Play purchase completes. Without this the user
    // would stay free until a manual restore or restart.
    _billing.onProChanged((pro) => state = pro);
    return false;
  }

  /// Completes when the first entitlement check has finished, successfully
  /// or not. Startup ordering (ads init, the scan flow's page cap) waits on
  /// this instead of racing the async load.
  Future<void> get ready => _firstLoad;

  Future<void> _load() async {
    try {
      state = await _billing.isPro();
    } catch (_) {
      // Offline or the store is unreachable: stay free for now. The store
      // listener above and Restore in Settings both correct this later.
    }
  }

  /// Runs the purchase and returns the outcome so the paywall can show the
  /// failure message instead of silently staying free.
  Future<Result<bool>> upgrade() async {
    final result = await _billing.purchasePro();
    if (result case Ok(value: final pro)) {
      state = pro;
    }
    return result;
  }

  Future<Result<bool>> restore() async {
    final result = await _billing.restore();
    if (result case Ok(value: final pro)) {
      state = pro;
    }
    return result;
  }
}

final billingProvider = NotifierProvider<BillingController, bool>(
  BillingController.new,
);
