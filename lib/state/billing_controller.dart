// Exposes one thing to the UI: is the user Pro. Everything gated reads this.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  throw UnimplementedError('Override in main() with the configured service.');
});

class BillingController extends StateNotifier<bool> {
  BillingController(this._billing) : super(false) {
    _load();
  }

  final BillingService _billing;

  Future<void> _load() async {
    state = await _billing.isPro();
  }

  Future<bool> upgrade() async {
    final result = await _billing.purchasePro();
    if (result case Ok(value: final pro)) {
      state = pro;
      return pro;
    }
    return false;
  }

  Future<void> restore() async {
    final result = await _billing.restore();
    if (result case Ok(value: final pro)) state = pro;
  }
}

final billingProvider =
    StateNotifierProvider<BillingController, bool>((ref) {
  return BillingController(ref.watch(billingServiceProvider));
});
