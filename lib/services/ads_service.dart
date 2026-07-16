// Wraps: google_mobile_ads 9.0.0 (AdMob), verified against the official
// Flutter guides on 2026-07-14. Everything AdMob touches lives behind this
// interface, so the screens never import the ad SDK and tests can fake it.
//
// Three rules this service enforces so the rest of the app does not have to:
//   1. Pro users never see an ad. The gate is here, not in the widgets.
//   2. Debug builds always serve Google's test ads. Clicking your own live
//      ads gets an AdMob account terminated.
//   3. No ad request happens until the UMP consent flow says it may, which
//      is what keeps the app legal in the EEA and the UK.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants.dart';
import '../core/secrets.dart';

/// The screens depend on this, never on the ad SDK.
abstract interface class AdsService {
  /// Runs consent, then initializes the SDK. Safe to call once at startup.
  Future<void> initialize();

  /// True when a real ad request is allowed right now.
  bool get canServeAds;

  /// The banner unit to load, or null when ads are off.
  String? get bannerAdUnitId;

  /// Counts a scan and shows an interstitial on every [AppLimits.scansPerAd]
  /// completed scan. Does nothing when ads are off.
  Future<void> onScanCompleted();

  /// Whether regulations require offering a way to revisit the ad-consent
  /// choice (EEA/UK). Drives the "Manage ad consent" entry in Settings.
  Future<bool> get privacyOptionsRequired;

  /// Shows the UMP privacy options form so the user can change their choice.
  Future<void> showPrivacyOptions();

  void dispose();
}

class AdMobAdsService implements AdsService {
  AdMobAdsService({required this.isPro});

  /// Read once at startup. The app is restarted-in-effect by a purchase, and
  /// the provider rebuilds this service when the Pro flag flips.
  final bool isPro;

  bool _consented = false;
  bool _initialized = false;
  bool _disposed = false;
  int _scanCount = 0;
  InterstitialAd? _interstitial;

  // Google's official sample units. Debug builds use these, always.
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Live units come from the git-ignored secrets file. While they are empty
  /// the release build simply runs without ads, which is the honest state
  /// before the AdMob account exists.
  String? get _liveBanner {
    final id = _isAndroid
        ? Secrets.admobBannerAndroid
        : Secrets.admobBannerIos;
    return id.isEmpty ? null : id;
  }

  String? get _liveInterstitial {
    final id = _isAndroid
        ? Secrets.admobInterstitialAndroid
        : Secrets.admobInterstitialIos;
    return id.isEmpty ? null : id;
  }

  @override
  bool get canServeAds => !isPro && _initialized && _consented;

  @override
  String? get bannerAdUnitId {
    if (!canServeAds) return null;
    if (kDebugMode) return _isAndroid ? _testBannerAndroid : _testBannerIos;
    return _liveBanner;
  }

  String? get _interstitialAdUnitId {
    if (!canServeAds) return null;
    if (kDebugMode) {
      return _isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return _liveInterstitial;
  }

  @override
  Future<void> initialize() async {
    if (isPro) return;

    await _gatherConsent();
    if (!_consented) return;

    await MobileAds.instance.initialize();
    _initialized = true;
    unawaited(_preloadInterstitial());
  }

  /// UMP runs at every launch. On any failure we fail closed: no consent
  /// means no ads, which is the safe side of the line to be on.
  Future<void> _gatherConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // The callback resolves the completer; the returned future carries
        // no result of its own. The try/finally guarantees the completer
        // resolves even if the consent check itself throws, otherwise
        // initialize() would hang forever with no retry.
        unawaited(
          ConsentForm.loadAndShowConsentFormIfRequired((error) async {
            try {
              _consented = error == null &&
                  await ConsentInformation.instance.canRequestAds();
            } catch (_) {
              _consented = false;
            } finally {
              if (!completer.isCompleted) completer.complete();
            }
          }),
        );
      },
      (FormError error) {
        _consented = false;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  Future<void> _preloadInterstitial() async {
    final unit = _interstitialAdUnitId;
    if (unit == null || _interstitial != null || _disposed) return;

    await InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // The load may finish after this service was replaced (e.g. the
          // user bought Pro mid-request). A dead service must not hold an ad.
          if (_disposed) {
            ad.dispose();
            return;
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              if (!_disposed) unawaited(_preloadInterstitial());
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitial = null;
            },
          );
          _interstitial = ad;
        },
        onAdFailedToLoad: (err) => _interstitial = null,
      ),
    );
  }

  /// An interstitial after every scan would make the app hostile, so it
  /// fires on every nth one and only once the scan is safely saved.
  @override
  Future<void> onScanCompleted() async {
    if (!canServeAds) return;

    _scanCount++;
    if (_scanCount % AppLimits.scansPerAd != 0) return;

    final ad = _interstitial;
    if (ad == null) {
      unawaited(_preloadInterstitial());
      return;
    }
    _interstitial = null;
    await ad.show();
  }

  @override
  Future<bool> get privacyOptionsRequired async {
    if (isPro || !_initialized) return false;
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    // The returned future completes when the form is dismissed.
    await ConsentForm.showPrivacyOptionsForm((_) {});
    // The user may have withdrawn consent; re-check before the next request.
    try {
      _consented = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      _consented = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _interstitial?.dispose();
    _interstitial = null;
  }
}

/// Used for Pro users and in tests. Every question answers no.
class NoAdsService implements AdsService {
  const NoAdsService();

  @override
  Future<void> initialize() async {}

  @override
  bool get canServeAds => false;

  @override
  String? get bannerAdUnitId => null;

  @override
  Future<void> onScanCompleted() async {}

  @override
  Future<bool> get privacyOptionsRequired async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  void dispose() {}
}
