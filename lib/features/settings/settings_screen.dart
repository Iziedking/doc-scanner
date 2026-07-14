// Settings: Pro status, upgrade and restore, and the privacy note. Kept small
// on purpose. The privacy policy page and onboarding land with milestone M6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';
import '../../state/billing_controller.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(billingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Plan'),
            subtitle: Text(isPro ? 'Pro' : 'Free'),
            trailing: isPro
                ? null
                : FilledButton.tonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const PaywallScreen()),
                    ),
                    child: const Text('Upgrade'),
                  ),
          ),
          ListTile(
            title: const Text('Restore purchase'),
            onTap: () => _restore(context, ref),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text('Your scans stay on this device.'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
