/// Copy this file to `secrets.dart` in the same folder and fill in your keys.
/// `secrets.dart` is git-ignored, so keys never land in the repo.
///
/// Every value can stay empty. Empty means the feature is off, not broken:
/// no RevenueCat keys means the app runs free-only, and no AdMob unit ids
/// means release builds serve no ads. That is the correct state before the
/// dashboards exist. Debug builds always serve Google's test ads regardless
/// of what is here, because clicking your own live ads gets an AdMob account
/// terminated.
class Secrets {
  // RevenueCat public SDK keys. Dashboard: Project settings, API keys.
  // These are safe to ship inside the app binary; they stay out of source
  // control only so the repo can be shared freely.
  static const String revenueCatAndroidKey = '';
  static const String revenueCatIosKey = '';

  // AdMob ad unit ids, from the AdMob console. The App ID is a separate
  // value that goes in AndroidManifest.xml and Info.plist, not here.
  static const String admobBannerAndroid = '';
  static const String admobBannerIos = '';
  static const String admobInterstitialAndroid = '';
  static const String admobInterstitialIos = '';
}
