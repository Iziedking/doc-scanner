// The scan flow: run the ML Kit scanner, then ask for a name, then save. Free
// users are capped at a page limit, which the platform scan UI enforces. Pro
// users get their pages OCR'd right after the save so search works on content.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/result.dart';
import '../../services/scanner_service.dart';
import '../../state/ads_controller.dart';
import '../../state/billing_controller.dart';
import '../../state/library_controller.dart';
import '../../state/ocr_runner.dart';
import 'name_document_sheet.dart';

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return MlKitScannerService();
});

Future<void> startScanFlow(BuildContext context, WidgetRef ref) async {
  final isPro = ref.read(billingProvider);
  final pageLimit =
      isPro ? AppLimits.proPagesPerDocument : AppLimits.freePagesPerDocument;

  final result =
      await ref.read(scannerServiceProvider).scan(pageLimit: pageLimit);

  switch (result) {
    case Err(message: final message):
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    case Ok(value: ScanCancelled()):
      return;
    case Ok(value: ScanPages(imagePaths: final imagePaths)):
      if (!context.mounted) return;
      final name = await showNameDocumentSheet(context);
      if (name == null || name.trim().isEmpty) return;

      final document = await ref
          .read(libraryProvider.notifier)
          .addFromScan(name.trim(), imagePaths);

      if (!isPro) {
        // The scan is saved and on screen before any ad appears. Never
        // interrupt the task itself.
        await ref.read(adsServiceProvider).onScanCompleted();
        return;
      }

      final ocr = await ref.read(ocrRunnerProvider).run(document);
      if (ocr case Err(message: final message)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
  }
}
