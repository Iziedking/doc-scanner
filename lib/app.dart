import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/ads_controller.dart';

class DocScanApp extends ConsumerStatefulWidget {
  const DocScanApp({super.key, required this.showOnboarding});

  /// True on first launch, decided in main() from shared preferences.
  final bool showOnboarding;

  @override
  ConsumerState<DocScanApp> createState() => _DocScanAppState();
}

class _DocScanAppState extends ConsumerState<DocScanApp> {
  @override
  void initState() {
    super.initState();
    // Ads start themselves: consent first, then the SDK, then a preloaded
    // interstitial. Runs after the first frame so the consent form has a
    // window to attach to. Pro users skip the whole thing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(adsServiceProvider).initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emikings DocScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Dark is the brand. The light theme exists and is ready; switch to
      // ThemeMode.system when a light pass has been reviewed on device.
      themeMode: ThemeMode.dark,
      home: widget.showOnboarding
          ? const OnboardingScreen()
          : const LibraryScreen(),
    );
  }
}
