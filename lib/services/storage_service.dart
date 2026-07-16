// Wraps: sqflite 2.4.3 and path_provider 2.1.6, verified on pub.dev
// 2026-07-13. Metadata lives in the database, page images and generated PDFs
// live as files in the app documents directory. The database never holds image
// bytes, only paths.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/doc_page.dart';
import '../models/document.dart';
import '../models/folder.dart';

/// The interface the controllers talk to. Widget tests fake this; unit tests
/// run the sqflite implementation against a real SQLite through ffi.
abstract interface class StorageService {
  Future<Document> createDocument({
    required String name,
    required List<String> scannedImagePaths,
    String? folderId,
  });
  Future<List<Document>> listDocuments({String? folderId, String? query});
  Future<void> renameDocument(String id, String name);
  Future<void> deleteDocument(String id);
  Future<void> setPageOcr(String pageId, String text);
  Future<Folder> createFolder(String name);
  Future<List<Folder>> listFolders();
  Future<void> deleteFolder(String id);
  Future<void> moveToFolder(String documentId, String? folderId);
}

class SqfliteStorageService implements StorageService {
  SqfliteStorageService._(this._db, this._filesDir);

  final Database _db;
  final Directory _filesDir;
  static const _uuid = Uuid();

  /// Open the database, create tables on first run, and make sure the images
  /// directory exists. Call once at startup. Tests pass their own [baseDir]
  /// and [dbFactory] (sqflite_common_ffi); the app uses the platform defaults.
  static Future<SqfliteStorageService> open({
    Directory? baseDir,
    DatabaseFactory? dbFactory,
  }) async {
    final docsDir = baseDir ?? await getApplicationDocumentsDirectory();
    final filesDir = Directory(p.join(docsDir.path, 'pages'));
    if (!filesDir.existsSync()) {
      filesDir.createSync(recursive: true);
    }

    final factory = dbFactory ?? databaseFactory;
    final db = await factory.openDatabase(
      p.join(docsDir.path, Db.fileName),
      options: OpenDatabaseOptions(
        version: Db.version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
      ),
    );
    return SqfliteStorageService._(db, filesDir);
  }

  /// The app never closes the database; tests do, so the file can be deleted.
  Future<void> close() => _db.close();

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

  /// Copy freshly scanned images into the app's own directory so they
  /// survive, then create the document and its page rows in one transaction.
  /// If the transaction fails, the copies are removed again so nothing is
  /// orphaned on disk.
  @override
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

    try {
      await _db.transaction((txn) async {
        await txn.insert('documents', document.toRow());
        for (final page in pages) {
          await txn.insert('pages', page.toRow());
        }
      });
    } catch (_) {
      for (final page in pages) {
        try {
          await File(page.imagePath).delete();
        } catch (_) {
          // Best effort; an unremovable copy is not worth masking the
          // original failure.
        }
      }
      rethrow;
    }
    return document;
  }

  Future<String> _persistImage(
      String sourcePath, String docId, int index) async {
    // Scanners on some platforms hand back file:// URIs with percent-encoded
    // characters (spaces become %20); Uri.toFilePath decodes them properly,
    // where a plain prefix strip would produce a nonexistent path.
    final src = File(
      sourcePath.startsWith('file://')
          ? Uri.parse(sourcePath).toFilePath()
          : sourcePath,
    );
    final ext = p.extension(src.path).isEmpty ? '.jpg' : p.extension(src.path);
    final dest = p.join(_filesDir.path, '${docId}_$index$ext');
    await src.copy(dest);
    return dest;
  }

  @override
  Future<List<Document>> listDocuments({String? folderId, String? query}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (folderId != null) {
      where.add('folder_id = ?');
      args.add(folderId);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add("(name LIKE ? ESCAPE '\\' OR id IN "
          "(SELECT document_id FROM pages WHERE ocr_text LIKE ? ESCAPE '\\'))");
      // % and _ are LIKE wildcards; searching for "100%" must not match
      // everything, so user text is escaped literally.
      final escaped = query
          .trim()
          .replaceAll('\\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      final like = '%$escaped%';
      args
        ..add(like)
        ..add(like);
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

  @override
  Future<void> renameDocument(String id, String name) async {
    await _db.update(
      'documents',
      {'name': name, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// The row goes first: if anything fails midway, a leftover image file on
  /// disk is invisible, but a surviving row pointing at deleted files would
  /// show broken thumbnails in the library.
  @override
  Future<void> deleteDocument(String id) async {
    final pages = await _loadPages(id);
    await _db.delete('documents', where: 'id = ?', whereArgs: [id]);
    for (final page in pages) {
      final f = File(page.imagePath);
      if (await f.exists()) await f.delete();
    }
  }

  @override
  Future<void> setPageOcr(String pageId, String text) async {
    await _db.update('pages', {'ocr_text': text},
        where: 'id = ?', whereArgs: [pageId]);
  }

  @override
  Future<Folder> createFolder(String name) async {
    final folder =
        Folder(id: _uuid.v4(), name: name, createdAt: DateTime.now());
    await _db.insert('folders', folder.toRow());
    return folder;
  }

  @override
  Future<List<Folder>> listFolders() async {
    final rows = await _db.query('folders', orderBy: 'name ASC');
    return rows.map(Folder.fromRow).toList();
  }

  /// Documents inside the folder move to the root, they are not deleted. The
  /// schema's ON DELETE SET NULL handles that.
  @override
  Future<void> deleteFolder(String id) async {
    await _db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> moveToFolder(String documentId, String? folderId) async {
    await _db.update(
      'documents',
      {
        'folder_id': folderId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }
}
