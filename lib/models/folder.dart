/// A folder groups documents. A document with a null folderId sits at the root.
class Folder {
  const Folder({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Folder.fromRow(Map<String, Object?> row) => Folder(
        id: row['id']! as String,
        name: row['name']! as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      );
}
