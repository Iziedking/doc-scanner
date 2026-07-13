// The upgrade screen. Lists what Pro unlocks and runs the RevenueCat purchase.
// Keep the copy honest: free stays useful, Pro removes friction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              onPressed: () async {
                final ok = await ref.read(billingProvider.notifier).upgrade();
                if (context.mounted && ok) Navigator.pop(context);
              },
              child: const Text('Upgrade'),
            ),
            TextButton(
              onPressed: () => ref.read(billingProvider.notifier).restore(),
              child: const Text('Restore purchase'),
            ),
          ],
        ),
      ),
    );
  }
}
