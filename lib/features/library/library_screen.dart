// The home screen. Brand header, search, folder chips, then the document
// list. Documents read as rows (thumbnail, name, date, page count) because a
// scan library is scanned by name and date, not by cover art. One accent on
// this screen: the Scan button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/document.dart';
import '../../state/library_controller.dart';
import '../scan/scan_flow.dart';
import '../settings/settings_screen.dart';
import '../viewer/viewer_screen.dart';
import 'document_actions_sheet.dart';
import 'document_row.dart';
import 'folder_bar.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search documents',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (q) =>
                    ref.read(libraryProvider.notifier).search(q),
              ),
            ),
            const FolderBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Documents',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  if (!state.loading)
                    Text(
                      '${state.documents.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.documents.isEmpty
                      ? _EmptyState(onScan: () => startScanFlow(context, ref))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                          itemCount: state.documents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final doc = state.documents[i];
                            return DocumentRow(
                              document: doc,
                              onTap: () => _openViewer(context, doc),
                              onMenu: () => showDocumentActionsSheet(
                                  context, ref, doc),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startScanFlow(context, ref),
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan'),
      ),
    );
  }

  void _openViewer(BuildContext context, Document doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ViewerScreen(document: doc)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Row(
        children: [
          Image.asset(BrandAssets.emblem, width: 28, height: 28),
          const SizedBox(width: 10),
          Text(
            'Emikings DocScan',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text('No documents yet',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Scan a paper document and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined, size: 20),
              label: const Text('Scan your first document'),
            ),
          ],
        ),
      ),
    );
  }
}
