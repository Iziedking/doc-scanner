import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/library/library_screen.dart';

class DocScanApp extends StatelessWidget {
  const DocScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const LibraryScreen(),
    );
  }
}
