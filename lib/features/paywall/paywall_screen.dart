// The upgrade screen. The emblem leads, the perks are concrete, the price
// button is the only gold on the screen. Keep the copy honest: free stays
// useful, Pro removes friction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../core/theme.dart';
import '../../state/billing_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _perks = [
    (Icons.layers_outlined, 'Unlimited pages', 'No cap per document.'),
    (Icons.text_fields, 'Text recognition', 'Every scan becomes searchable.'),
    (Icons.branding_watermark_outlined, 'Clean exports',
        'No watermark on your PDFs.'),
    (Icons.picture_as_pdf_outlined, 'PDF tools',
        'Merge, reorder, and compress.'),
    (Icons.cloud_outlined, 'Cloud backup', 'Coming soon, included in Pro.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Image.asset(BrandAssets.emblem, width: 72, height: 72),
              ),
              const SizedBox(height: 16),
              Text(
                'DocScan Pro',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'For people who scan every day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              for (final (icon, title, detail) in _perks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            Text(detail,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () => _upgrade(context, ref),
                child: const Text('Upgrade to Pro'),
              ),
              TextButton(
                onPressed: () => _restore(context, ref),
                child: const Text('Restore purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(billingProvider.notifier).upgrade();
    if (!context.mounted) return;
    switch (result) {
      case Ok(value: true):
        Navigator.pop(context);
      case Ok(value: false):
        break; // The user backed out of the store sheet. Nothing to say.
      case Err(message: final m):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(billingProvider.notifier).restore();
    if (!context.mounted) return;
    final message = switch (result) {
      Ok(value: true) => 'Pro restored.',
      Ok(value: false) => 'No previous purchase was found.',
      Err(message: final m) => m,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
