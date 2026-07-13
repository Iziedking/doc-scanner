// App entry. Opens the storage service and configures billing, then injects
// both into the Riverpod providers the UI reads. Keep startup work here so the
// widgets stay free of setup logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/billing_service.dart';
import 'services/storage_service.dart';
import 'state/billing_controller.dart';
import 'state/library_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.open();

  final billing = RevenueCatBillingService();
  // Replace with your RevenueCat public SDK key. It is safe to ship in the app,
  // but load it from a git-ignored config rather than hardcoding here.
  // await billing.init(Secrets.revenueCatPublicKey);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        billingServiceProvider.overrideWithValue(billing),
      ],
      child: const DocScanApp(),
    ),
  );
}
