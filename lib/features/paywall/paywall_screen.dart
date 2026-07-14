// The upgrade screen. Lists what Pro unlocks and runs the RevenueCat purchase.
// Keep the copy honest: free stays useful, Pro removes friction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../state/billing_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _perks = [
    'Remove the export watermark',
    'Unlimited pages per document',
    'Text recognition and search',
    'Merge, reorder, and compress PDFs',
    'Cloud backup',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('DocScan Pro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Upgrade to Pro',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (final perk in _perks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(perk)),
                  ],
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: () => _upgrade(context, ref),
              child: const Text('Upgrade'),
            ),
            TextButton(
              onPressed: () => _restore(context, ref),
              child: const Text('Restore purchase'),
            ),
          ],
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
