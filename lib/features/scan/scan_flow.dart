// The scan flow: run the ML Kit scanner, then ask for a name, then save. Free
// users are capped at a page limit; the cap is where the paywall nudge lives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/result.dart';
import '../../services/scanner_service.dart';
import '../../state/billing_controller.dart';
import '../../state/library_controller.dart';
import 'name_document_sheet.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return MlKitScannerService();
});

Future<void> startScanFlow(BuildContext context, WidgetRef ref) async {
  final isPro = ref.read(billingProvider);
  final pageLimit = isPro ? 100 : AppLimits.freePagesPerDocument;

  final result = await ref.read(scannerServiceProvider).scan(pageLimit: pageLimit);

  switch (result) {
    case Err(message: final message):
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    case Ok(value: final outcome):
      if (!context.mounted) return;
      final name = await showNameDocumentSheet(context);
      if (name == null || name.trim().isEmpty) return;
      await ref
          .read(libraryProvider.notifier)
          .addFromScan(name.trim(), outcome.imagePaths);
  }
}
