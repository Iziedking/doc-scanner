// The ads service, rebuilt whenever the Pro flag changes. Buying Pro tears
// down the AdMob service and replaces it with the one that answers no to
// everything, so the ads disappear without a restart.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads_service.dart';
import 'billing_controller.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  final isPro = ref.watch(billingProvider);
  if (isPro) return const NoAdsService();

  final service = AdMobAdsService(isPro: false);
  ref.onDispose(service.dispose);
  return service;
});

/// False until the startup sequence in app.dart has finished consent and SDK
/// init. The banner watches this: initialization ends after the first frame,
/// so without a signal the banner would ask for its unit id too early, get
/// null, and never try again.
class AdsReady extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() => state = true;
}

final adsReadyProvider = NotifierProvider<AdsReady, bool>(AdsReady.new);

/// Whether Settings should offer the "Manage ad consent" entry. UMP only
/// answers this after the consent info update inside initialize(), hence the
/// adsReady dependency.
final privacyOptionsRequiredProvider = FutureProvider<bool>((ref) {
  ref.watch(adsReadyProvider);
  return ref.watch(adsServiceProvider).privacyOptionsRequired;
});
