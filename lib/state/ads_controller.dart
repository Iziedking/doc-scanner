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
