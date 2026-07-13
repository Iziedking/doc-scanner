// Wraps: sqflite + path_provider. Metadata in the database, page images and
// generated PDFs as files in the app documents directory. The database never
// holds image bytes, only paths.
// Verify sqflite and path_provider APIs on pub.dev before shipping.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/doc_page.dart';
import '../models/document.dart';
import '../models/folder.dart';

class StorageService {
  StorageService._(this._db, this._filesDir);

  final Database _db;
  final Directory _filesDir;
  static const _uuid = Uuid();

  /// Open the database, create tables on first run, and make sure the images
  /// directory exists. Call once at startup.
  static Future<StorageService> open() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory(p.join(docsDir.path, 'pages'));
    if (!filesDir.existsSync()) {
      filesDir.createSync(recursive: true);
    }

    final db = await openDatabase(
      p.join(docsDir.path, Db.fileName),
      version: Db.version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    return StorageService._(db, filesDir);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        ocr_text TEXT,
        page_order INTEGER NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Move freshly scanned images into the app's own directory so they survive,
  /// then create the document and its page rows in one transaction.
  Future<Document> createDocument({
    required String name,
    required List<String> scannedImagePaths,
    String? folderId,
  }) async {
    final now = DateTime.now();
    final docId = _uuid.v4();

    final pages = <DocPage>[];
    for (var i = 0; i < scannedImagePaths.length; i++) {
      final stored = await _persistImage(scannedImagePaths[i], docId, i);
      pages.add(DocPage(
        id: _uuid.v4(),
        documentId: docId,
        imagePath: stored,
        order: i,
      ));
    }

    final document = Document(
      id: docId,
      name: name,
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
      pages: pages,
    );

    await _db.transaction((txn) async {
      await txn.insert('documents', document.toRow());
      for (final page in pages) {
        await txn.insert('pages', page.toRow());
      }
    });
    return document;
  }

  Future<String> _persistImage(String sourcePath, String docId, int index) async {
    final src = File(sourcePath.replaceFirst('file://', ''));
    final ext = p.extension(src.path).isEmpty ? '.jpg' : p.extension(src.path);
    final dest = p.join(_filesDir.path, '${docId}_$index$ext');
    await src.copy(dest);
    return dest;
  }

  Future<List<Document>> listDocuments({String? folderId, String? query}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (folderId != null) {
      where.add('folder_id = ?');
      args.add(folderId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('(name LIKE ? OR id IN '
          '(SELECT document_id FROM pages WHERE ocr_text LIKE ?))');
      final like = '%${query.trim()}%';
      args..add(like)..add(like);
    }

    final rows = await _db.query(
      'documents',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );

    final docs = <Document>[];
    for (final row in rows) {
      final pages = await _loadPages(row['id']! as String);
      docs.add(Document.fromRow(row, pages: pages));
    }
    return docs;
  }

  Future<List<DocPage>> _loadPages(String documentId) async {
    final rows = await _db.query(
      'pages',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_order ASC',
    );
    return rows.map(DocPage.fromRow).toList();
  }

  Future<void> renameDocument(String id, String name) async {
    await _db.update(
      'documents',
      {'name': name, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final pages = await _loadPages(id);
    for (final page in pages) {
      final f = File(page.imagePath);
      if (f.existsSync()) f.deleteSync();
    }
    await _db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPageOcr(String pageId, String text) async {
    await _db.update('pages', {'ocr_text': text},
        where: 'id = ?', whereArgs: [pageId]);
  }

  Future<Folder> createFolder(String name) async {
    final folder =
        Folder(id: _uuid.v4(), name: name, createdAt: DateTime.now());
    await _db.insert('folders', folder.toRow());
    return folder;
  }

  Future<List<Folder>> listFolders() async {
    final rows = await _db.query('folders', orderBy: 'name ASC');
    return rows.map(Folder.fromRow).toList();
  }

  Future<void> moveToFolder(String documentId, String? folderId) async {
    await _db.update(
      'documents',
      {'folder_id': folderId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }
}
