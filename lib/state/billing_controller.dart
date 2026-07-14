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

  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    state = await _billing.isPro();
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
