// Settings: the plan, purchase recovery, and the privacy story. Grouped and
// small on purpose; a scanner's settings should not need a search field.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../core/theme.dart';
import '../../state/billing_controller.dart';
import '../paywall/paywall_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(billingProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isPro
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: isPro ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPro ? 'DocScan Pro' : 'Free plan',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(
                          isPro
                              ? 'Everything is unlocked.'
                              : 'Up to 5 pages per scan, watermarked exports.',
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const PaywallScreen()),
                      ),
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Purchases'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore),
            title: const Text('Restore purchase'),
            onTap: () => _restore(context, ref),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Privacy'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy policy'),
            subtitle: const Text('Your scans stay on this device.'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _SectionLabel('About'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Image.asset(BrandAssets.emblem, width: 32, height: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emikings DocScan',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('An EMIKINGS product',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
