// The privacy policy, readable in the app because the honest version fits on
// one screen. The Play Store data safety form must say the same things.

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'Your documents stay on your device',
      'Every scan, page image, and recognized text is stored only on this '
          'phone. DocScan has no server and no account system. Nothing you '
          'scan is uploaded anywhere unless you choose to share or export it '
          'yourself.',
    ),
    (
      'Camera',
      'Scanning uses the document scanner provided by your phone\'s system '
          'services. On Android, DocScan itself never accesses your camera '
          'directly and does not request the camera permission. The camera '
          'image is used only to capture the pages you keep.',
    ),
    (
      'Text recognition',
      'Reading text from your scans happens entirely on this device. The '
          'text is stored alongside the scan so you can search it, and it '
          'leaves the phone only if you export the document.',
    ),
    (
      'Advertising',
      'The free version shows ads from Google AdMob. To show them, AdMob '
          'receives your device\'s advertising identifier and general '
          'information about your device, and it may use these to personalize '
          'ads. It never receives your documents. In regions that require it, '
          'you are asked for consent before any ad loads, you can decline, and '
          'you can change that choice later under Manage ad consent in '
          'Settings. Upgrading to Pro removes ads completely.',
    ),
    (
      'Purchases',
      'If you upgrade to Pro, the purchase is processed by the app store and '
          'our billing provider, RevenueCat. They receive purchase details, '
          'never your documents.',
    ),
    (
      'Deleting your data',
      'Deleting a document removes its images and text from the device. '
          'Uninstalling the app removes everything.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          for (final (title, body) in _sections) ...[
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
