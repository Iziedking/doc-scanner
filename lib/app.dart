import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/library/library_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class DocScanApp extends StatelessWidget {
  const DocScanApp({super.key, required this.showOnboarding});

  /// True on first launch, decided in main() from shared preferences.
  final bool showOnboarding;

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
      home: showOnboarding ? const OnboardingScreen() : const LibraryScreen(),
    );
  }
}
