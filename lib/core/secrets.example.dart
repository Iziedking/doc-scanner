/// Copy this file to `secrets.dart` in the same folder and fill in your keys.
/// `secrets.dart` is git-ignored, so keys never land in the repo.
///
/// RevenueCat public SDK keys are safe to ship inside the app binary, but they
/// still stay out of source control so the repo can be shared freely. Get them
/// from the RevenueCat dashboard under Project settings, API keys.
class Secrets {
  /// Leave a key empty and the app runs in free mode with billing off. That is
  /// the normal state during development, before the dashboards are set up.
  static const String revenueCatAndroidKey = '';
  static const String revenueCatIosKey = '';
}
