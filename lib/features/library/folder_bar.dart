// A horizontal row of folder chips under the search field: All, one chip per
// folder, and a New folder chip. Selecting a chip filters the grid. Long-press
// a folder chip to delete it; its documents move back to All.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_prompt_dialog.dart';
import '../../models/folder.dart';
import '../../state/library_controller.dart';

class FolderBar extends ConsumerWidget {
  const FolderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: state.selectedFolderId == null,
              onSelected: (_) =>
                  ref.read(libraryProvider.notifier).selectFolder(null),
            ),
          ),
          for (final folder in state.folders)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: () => _confirmDeleteFolder(context, ref, folder),
                child: ChoiceChip(
                  label: Text(folder.name),
                  selected: state.selectedFolderId == folder.id,
                  onSelected: (_) => ref
                      .read(libraryProvider.notifier)
                      .selectFolder(folder.id),
                ),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: const Text('New folder'),
            onPressed: () => _promptNewFolder(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _promptNewFolder(BuildContext context, WidgetRef ref) async {
    final name = await showTextPromptDialog(
      context,
      title: 'New folder',
      confirmLabel: 'Create',
      hint: 'Folder name',
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await ref.read(libraryProvider.notifier).createFolder(name.trim());
  }

  Future<void> _confirmDeleteFolder(
      BuildContext context, WidgetRef ref, Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder'),
        content: Text(
            'Delete "${folder.name}"? Its documents move back to All.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(libraryProvider.notifier).deleteFolder(folder.id);
  }
}
