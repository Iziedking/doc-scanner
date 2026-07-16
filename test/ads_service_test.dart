// The ad gates, tested without touching the AdMob SDK. The rule that matters
// most: a Pro user must never trigger an ad request, no matter what else is
// true, so canServeAds and every unit id must stay off for them.

import 'package:docscan/services/ads_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Pro user is served nothing', () async {
    final ads = AdMobAdsService(isPro: true);
    await ads.initialize();

    expect(ads.canServeAds, isFalse);
    expect(ads.bannerAdUnitId, isNull);

    // Must not throw, and must not show anything.
    await ads.onScanCompleted();
    ads.dispose();
  });

  test('a free user gets nothing until consent and init have happened',
      () async {
    // Freshly constructed, before initialize(), nothing is consented and the
    // SDK is not up, so no ad may be requested.
    final ads = AdMobAdsService(isPro: false);

    expect(ads.canServeAds, isFalse);
    expect(ads.bannerAdUnitId, isNull);
    ads.dispose();
  });

  test('the no-ads service answers no to everything', () async {
    const ads = NoAdsService();
    await ads.initialize();

    expect(ads.canServeAds, isFalse);
    expect(ads.bannerAdUnitId, isNull);
    expect(await ads.privacyOptionsRequired, isFalse);
    await ads.onScanCompleted();
  });

  test('privacy options are never offered to Pro or before init', () async {
    final pro = AdMobAdsService(isPro: true);
    expect(await pro.privacyOptionsRequired, isFalse);
    pro.dispose();

    // Before initialize() the UMP status is unknown; the answer must be no
    // without touching the SDK (which would crash in a test).
    final free = AdMobAdsService(isPro: false);
    expect(await free.privacyOptionsRequired, isFalse);
    free.dispose();
  });
}
