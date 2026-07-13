// The home screen: a grid of saved documents, a search field, and the scan
// button. Watches the library controller and kicks off the scan flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/library_controller.dart';
import '../scan/scan_flow.dart';
import '../viewer/viewer_screen.dart';
import 'document_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DocScan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search documents',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (q) => ref.read(libraryProvider.notifier).search(q),
            ),
          ),
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ViewerScreen(document: doc),
                              ),
                            ),
                            onDelete: () =>
                                ref.read(libraryProvider.notifier).delete(doc.id),
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
