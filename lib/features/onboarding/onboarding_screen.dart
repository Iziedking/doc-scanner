// First-run onboarding: three pages, one idea each, then into the app. The
// privacy page is the pitch that separates DocScan from the big scanners, so
// it goes last and lands right before the user starts.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/library_screen.dart';
import 'onboarding_art.dart';

/// The flag main() reads at startup to skip straight to the library.
const String onboardingSeenKey = 'onboarding_seen';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      OnboardingArt.scan,
      'Scan anything',
      'Point the camera at any paper. Edges, perspective, and shadows are '
          'handled for you.',
    ),
    (
      OnboardingArt.organize,
      'Keep it in order',
      'Name your scans, sort them into folders, and find any document by '
          'searching for it.',
    ),
    (
      OnboardingArt.private,
      'Private by design',
      'Your documents never leave this phone unless you share them. No '
          'account, no cloud, no tracking.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingSeenKey, true);
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LibraryScreen()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (art, title, body) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: OnboardingIllustration(art),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        Container(
                          width: i == _page ? 20 : 6,
                          height: 6,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                              duration:
                                  const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            ),
                    child: Text(isLast ? 'Start scanning' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
