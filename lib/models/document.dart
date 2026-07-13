import 'doc_page.dart';

/// A saved document: a named, ordered set of scanned pages, optionally in a
/// folder. Pages are loaded alongside it when the viewer needs them.
class Document {
  const Document({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.pages = const [],
  });

  final String id;
  final String name;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DocPage> pages;

  int get pageCount => pages.length;

  /// The first page's image, used as the library thumbnail. Null when empty.
  String? get thumbnailPath => pages.isEmpty ? null : pages.first.imagePath;

  Document copyWith({
    String? name,
    String? folderId,
    DateTime? updatedAt,
    List<DocPage>? pages,
  }) =>
      Document(
        id: id,
        name: name ?? this.name,
        folderId: folderId ?? this.folderId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        pages: pages ?? this.pages,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'folder_id': folderId,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Document.fromRow(Map<String, Object?> row,
          {List<DocPage> pages = const []}) =>
      Document(
        id: row['id']! as String,
        name: row['name']! as String,
        folderId: row['folder_id'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
        pages: pages,
      );
}
