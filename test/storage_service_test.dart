// Storage round-trips against a real SQLite through sqflite_common_ffi, no
// device needed. Covers create, list, rename, delete, search by name and by
// OCR text, and folder moves including the delete-folder ON DELETE SET NULL
// behavior.

import 'dart:io';

import 'package:docscan/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late SqfliteStorageService storage;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docscan_test_');
    storage = await SqfliteStorageService.open(
      baseDir: tempDir,
      dbFactory: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await storage.close();
    await tempDir.delete(recursive: true);
  });

  /// A stand-in for a scanner output file. Content does not matter here; the
  /// storage layer only copies it.
  Future<String> fakeScanImage(String name) async {
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes([1, 2, 3]);
    return file.path;
  }

  test('create and list keeps name, page count, and page order', () async {
    final a = await fakeScanImage('a.jpg');
    final b = await fakeScanImage('b.jpg');

    await storage.createDocument(name: 'Tax form', scannedImagePaths: [a, b]);

    final docs = await storage.listDocuments();
    expect(docs, hasLength(1));
    expect(docs.first.name, 'Tax form');
    expect(docs.first.pageCount, 2);
    expect(docs.first.pages.map((page) => page.order).toList(), [0, 1]);
  });

  test('copied page images survive after the scanner file is gone', () async {
    final a = await fakeScanImage('a.jpg');
    final doc =
        await storage.createDocument(name: 'Receipt', scannedImagePaths: [a]);

    await File(a).delete();
    expect(File(doc.pages.first.imagePath).existsSync(), isTrue);
  });

  test('rename changes the name', () async {
    final a = await fakeScanImage('a.jpg');
    final doc =
        await storage.createDocument(name: 'Untitled', scannedImagePaths: [a]);

    await storage.renameDocument(doc.id, 'Lease agreement');

    final docs = await storage.listDocuments();
    expect(docs.single.name, 'Lease agreement');
  });

  test('delete removes the row and the page files', () async {
    final a = await fakeScanImage('a.jpg');
    final doc =
        await storage.createDocument(name: 'Old scan', scannedImagePaths: [a]);
    final storedPath = doc.pages.first.imagePath;

    await storage.deleteDocument(doc.id);

    expect(await storage.listDocuments(), isEmpty);
    expect(File(storedPath).existsSync(), isFalse);
  });

  test('search matches document names', () async {
    final a = await fakeScanImage('a.jpg');
    final b = await fakeScanImage('b.jpg');
    await storage.createDocument(name: 'Passport copy', scannedImagePaths: [a]);
    await storage.createDocument(name: 'Grocery list', scannedImagePaths: [b]);

    final hits = await storage.listDocuments(query: 'pass');
    expect(hits.single.name, 'Passport copy');
  });

  test('search matches OCR text once a page has it', () async {
    final a = await fakeScanImage('a.jpg');
    final doc =
        await storage.createDocument(name: 'Scan 12', scannedImagePaths: [a]);

    expect(await storage.listDocuments(query: 'invoice'), isEmpty);

    await storage.setPageOcr(doc.pages.first.id, 'Invoice number 4411');

    final hits = await storage.listDocuments(query: 'invoice');
    expect(hits.single.id, doc.id);
  });

  test('search treats LIKE wildcards as literal text', () async {
    final a = await fakeScanImage('a.jpg');
    final b = await fakeScanImage('b.jpg');
    await storage.createDocument(
        name: 'Discount 100%', scannedImagePaths: [a]);
    await storage.createDocument(name: 'Grocery list', scannedImagePaths: [b]);

    // Unescaped, "%" matches everything and "_" matches any character.
    final percent = await storage.listDocuments(query: '100%');
    expect(percent.single.name, 'Discount 100%');
    expect(await storage.listDocuments(query: '_'), isEmpty);
  });

  test('accepts file:// URIs with percent-encoded characters', () async {
    final file = File(p.join(tempDir.path, 'scan page.jpg'));
    await file.writeAsBytes([1, 2, 3]);
    final uri = Uri.file(file.path).toString();
    expect(uri, contains('%20'), reason: 'the space must be encoded');

    final doc = await storage
        .createDocument(name: 'Spaced', scannedImagePaths: [uri]);
    expect(File(doc.pages.first.imagePath).existsSync(), isTrue);
  });

  test('folders filter documents and deleting one moves them to root',
      () async {
    final a = await fakeScanImage('a.jpg');
    final b = await fakeScanImage('b.jpg');
    final folder = await storage.createFolder('Work');
    final inFolder = await storage.createDocument(
        name: 'Contract', scannedImagePaths: [a], folderId: folder.id);
    await storage.createDocument(name: 'Personal', scannedImagePaths: [b]);

    final filtered = await storage.listDocuments(folderId: folder.id);
    expect(filtered.single.id, inFolder.id);

    await storage.deleteFolder(folder.id);

    expect(await storage.listFolders(), isEmpty);
    final all = await storage.listDocuments();
    expect(all, hasLength(2));
    expect(all.every((d) => d.folderId == null), isTrue,
        reason: 'ON DELETE SET NULL should move documents to the root');
  });

  test('moveToFolder updates the document', () async {
    final a = await fakeScanImage('a.jpg');
    final folder = await storage.createFolder('Home');
    final doc =
        await storage.createDocument(name: 'Warranty', scannedImagePaths: [a]);

    await storage.moveToFolder(doc.id, folder.id);
    expect((await storage.listDocuments(folderId: folder.id)).single.id, doc.id);

    await storage.moveToFolder(doc.id, null);
    expect(await storage.listDocuments(folderId: folder.id), isEmpty);
  });
}
