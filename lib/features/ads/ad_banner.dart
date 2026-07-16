// The only widget that touches the ad SDK. It renders nothing at all when
// ads are off, so Pro users and un-consented users see no empty gap.
//
// An AdWidget may be attached to a BannerAd exactly once, so the ad is
// created by this state, owned by it, and disposed with it. The widget
// watches the ads service and the ready flag: startup initialization ends
// after the first frame, so the first build always sees a null unit id and
// the request has to happen when the flag flips, not on a one-shot timer.
// Watching the service also removes the banner the moment Pro is bought.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme.dart';
import '../../services/ads_service.dart';
import '../../state/ads_controller.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;

  /// The service the current ad (or in-flight request) belongs to. A request
  /// happens at most once per service instance; a new instance after a Pro
  /// purchase resets it.
  AdsService? _requestedFor;

  Future<void> _load(AdsService service, String unitId) async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted || _requestedFor != service) return;

    // The listener, not the future, tells us when the ad is ready.
    unawaited(
      BannerAd(
        adUnitId: unitId,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            // The widget may be gone, or the service swapped, by the time
            // the network answers. Either way this ad has no home.
            if (!mounted || _requestedFor != service) {
              ad.dispose();
              return;
            }
            setState(() => _ad = ad as BannerAd);
          },
          onAdFailedToLoad: (ad, err) => ad.dispose(),
        ),
      ).load(),
    );
  }

  void _dropAd() {
    _ad?.dispose();
    _ad = null;
  }

  @override
  void dispose() {
    _dropAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(adsServiceProvider);
    // Rebuilds this widget when startup initialization finishes.
    ref.watch(adsReadyProvider);

    final unitId = service.bannerAdUnitId;
    if (unitId == null) {
      // Ads are off: Pro, no consent, or not initialized yet. Drop any
      // banner left over from a previous service so an upgrade removes it
      // immediately instead of at the next restart.
      _dropAd();
      _requestedFor = null;
      return const SizedBox.shrink();
    }

    if (_requestedFor != service) {
      _requestedFor = service;
      unawaited(_load(service, unitId));
    }

    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BrandColors.hairline)),
      ),
      child: AdWidget(ad: ad),
    );
  }
}
