// The only widget that touches the ad SDK. It renders nothing at all when
// ads are off, so Pro users and un-consented users see no empty gap.
//
// An AdWidget may be attached to a BannerAd exactly once, so the ad is
// created in initState, owned by this state, and disposed with it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme.dart';
import '../../state/ads_controller.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _ad;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs MediaQuery for the adaptive width, so it cannot run in initState.
    if (!_requested) {
      _requested = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final unitId = ref.read(adsServiceProvider).bannerAdUnitId;
    if (unitId == null || !mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    // The listener, not the future, tells us when the ad is ready.
    unawaited(
      BannerAd(
        adUnitId: unitId,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
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

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
