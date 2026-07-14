/// Single source of truth for limits and keys. No magic numbers in the widgets.
class AppLimits {
  /// Free users can save up to this many pages per document.
  static const int freePagesPerDocument = 5;

  /// "Unlimited" for Pro still needs a number, because the ML Kit scan UI
  /// takes a page limit. High enough that nobody hits it in one sitting.
  static const int proPagesPerDocument = 100;

  /// The ML Kit scanner needs a device with at least this much RAM, per the
  /// ML Kit docs. Below it the API returns UNSUPPORTED.
  static const int minRamMb = 1700;
}

class Entitlements {
  /// The one entitlement the whole app reads. Set this to match the identifier
  /// you create in the RevenueCat dashboard.
  static const String pro = 'pro';
}

class Db {
  static const String fileName = 'docscan.db';
  static const int version = 1;
}
