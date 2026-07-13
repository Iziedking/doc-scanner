// Settings: Pro status, restore, and the privacy note. Kept small on purpose.
// TODO: add the privacy policy page and an onboarding entry for the on-device
// privacy story before the store review (milestone M6).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/billing_controller.dart';

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
          ),
          ListTile(
            title: const Text('Restore purchase'),
            onTap: () => ref.read(billingProvider.notifier).restore(),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text('Your scans stay on this device.'),
          ),
        ],
      ),
    );
  }
}
