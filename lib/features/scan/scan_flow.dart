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
  // Right after a cold start the entitlement may still be loading; waiting
  // here keeps a Pro user from being page-capped or counted toward an ad.
  await ref.read(billingProvider.notifier).ready;
  if (!context.mounted) return;

  final isPro = ref.read(billingProvider);
  final pageLimit =
      isPro ? AppLimits.proPagesPerDocument : AppLimits.freePagesPerDocument;

  final result =
      await ref.read(scannerServiceProvider).scan(pageLimit: pageLimit);
  if (!context.mounted) return;

  switch (result) {
    case Err(message: final message):
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    case Ok(value: ScanCancelled()):
      return;
    case Ok(value: ScanPages(imagePaths: final imagePaths)):
      final name = await _askForName(context);
      if (name == null) return;
      if (!context.mounted) return;

      final document = await ref
          .read(libraryProvider.notifier)
          .addFromScan(name, imagePaths);
      if (!context.mounted) return;

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

/// Asks for a name, and treats a dismissed sheet as a question, not an
/// answer: the pages already exist, so throwing them away silently would
/// lose real work. One confirmation, then one more chance to name it.
Future<String?> _askForName(BuildContext context) async {
  final name = await showNameDocumentSheet(context);
  if (name != null && name.trim().isNotEmpty) return name.trim();
  if (!context.mounted) return null;

  final discard = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Discard this scan?'),
      content: const Text('The scanned pages will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  if (discard ?? true) return null;
  if (!context.mounted) return null;

  final retry = await showNameDocumentSheet(context);
  if (retry == null || retry.trim().isEmpty) return null;
  return retry.trim();
}
