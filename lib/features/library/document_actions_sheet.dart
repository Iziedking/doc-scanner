// The long-press menu for a document: rename, move to a folder, delete.
// Delete asks for confirmation; the other two open their own small prompts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/text_prompt_dialog.dart';
import '../../models/document.dart';
import '../../state/library_controller.dart';

Future<void> showDocumentActionsSheet(
    BuildContext context, WidgetRef ref, Document document) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(document.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(document.pageCountLabel),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(ctx);
              _promptRename(context, ref, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Move to folder'),
            onTap: () {
              Navigator.pop(ctx);
              _promptMove(context, ref, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, ref, document);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _promptRename(
    BuildContext context, WidgetRef ref, Document document) async {
  final name = await showTextPromptDialog(
    context,
    title: 'Rename document',
    confirmLabel: 'Save',
    initialText: document.name,
  );
  if (name == null || name.trim().isEmpty || !context.mounted) return;
  await ref.read(libraryProvider.notifier).rename(document.id, name.trim());
}

Future<void> _promptMove(
    BuildContext context, WidgetRef ref, Document document) async {
  final folders = ref.read(libraryProvider).folders;
  final choice = await showModalBottomSheet<String?>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Move to')),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('No folder'),
            onTap: () => Navigator.pop(ctx, ''),
          ),
          for (final folder in folders)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(folder.name),
              onTap: () => Navigator.pop(ctx, folder.id),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  await ref
      .read(libraryProvider.notifier)
      .moveToFolder(document.id, choice.isEmpty ? null : choice);
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, Document document) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete document'),
      content: Text('Delete "${document.name}"? This cannot be undone.'),
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
  await ref.read(libraryProvider.notifier).delete(document.id);
}
