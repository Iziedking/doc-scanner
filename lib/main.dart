// App entry. Opens the storage service, configures billing, and checks the
// first-run flag, then injects everything into the Riverpod providers the UI
// reads. Keep startup work here so the widgets stay free of setup logic.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/secrets.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/billing_service.dart';
import 'services/storage_service.dart';
import 'state/billing_controller.dart';
import 'state/library_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await SqfliteStorageService.open();
  final billing = await _configureBilling();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool(onboardingSeenKey) ?? false);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWith((ref) => storage),
        billingServiceProvider.overrideWith((ref) => billing),
      ],
      child: DocScanApp(showOnboarding: showOnboarding),
    ),
  );
}

/// RevenueCat keys are per store. An empty key means the dashboards are not
/// set up yet, so the app runs in free mode instead of crashing at startup.
Future<BillingService> _configureBilling() async {
  final key = Platform.isAndroid
      ? Secrets.revenueCatAndroidKey
      : Secrets.revenueCatIosKey;
  if (key.isEmpty) {
    return FreeBillingService();
  }
  final billing = RevenueCatBillingService();
  await billing.init(key);
  return billing;
}
