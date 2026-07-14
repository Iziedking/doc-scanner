// One document in the library list: page thumbnail, name, date and page
// count, and an overflow menu. Tap opens the viewer, the menu holds the rest.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/document.dart';

class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    required this.onTap,
    required this.onMenu,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = document.thumbnailPath;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 44,
                  height: 56,
                  child: thumb == null
                      ? ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(Icons.description_outlined,
                              size: 20, color: scheme.outline),
                        )
                      : Image.file(File(thumb), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(document.updatedAt)}  ·  '
                      '${document.pageCountLabel}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: 'Document actions',
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
