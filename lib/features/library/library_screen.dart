// The home screen: folder chips, a search field, a grid of saved documents,
// and the scan button. Watches the library controller and kicks off the scan
// flow. Long-press on a document opens its action sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/document.dart';
import '../../state/library_controller.dart';
import '../scan/scan_flow.dart';
import '../settings/settings_screen.dart';
import '../viewer/viewer_screen.dart';
import 'document_actions_sheet.dart';
import 'document_tile.dart';
import 'folder_bar.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search documents',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (q) => ref.read(libraryProvider.notifier).search(q),
            ),
          ),
          const FolderBar(),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.documents.isEmpty
                    ? const _EmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: state.documents.length,
                        itemBuilder: (context, i) {
                          final doc = state.documents[i];
                          return DocumentTile(
                            document: doc,
                            onTap: () => _openViewer(context, doc),
                            onLongPress: () =>
                                showDocumentActionsSheet(context, ref, doc),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startScanFlow(context, ref),
        icon: const Icon(Icons.document_scanner),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('No documents yet'),
          const SizedBox(height: 4),
          const Text('Tap Scan to add your first one.'),
        ],
      ),
    );
  }
}
