// An in-memory StorageService for widget tests. No files, no database. Seeded
// documents carry no pages so tiles render the placeholder instead of
// Image.file, which would fail in a test environment.

import 'package:docscan/models/doc_page.dart';
import 'package:docscan/models/document.dart';
import 'package:docscan/models/folder.dart';
import 'package:docscan/services/storage_service.dart';

class FakeStorageService implements StorageService {
  FakeStorageService({List<Document>? seed}) : _documents = [...?seed];

  final List<Document> _documents;
  final List<Folder> _folders = [];
  int _nextId = 0;

  String _newId() => 'fake-${_nextId++}';

  @override
  Future<Document> createDocument({
    required String name,
    required List<String> scannedImagePaths,
    String? folderId,
  }) async {
    final docId = _newId();
    final now = DateTime.now();
    final doc = Document(
      id: docId,
      name: name,
      folderId: folderId,
      createdAt: now,
      updatedAt: now,
      pages: [
        for (var i = 0; i < scannedImagePaths.length; i++)
          DocPage(
            id: _newId(),
            documentId: docId,
            imagePath: scannedImagePaths[i],
            order: i,
          ),
      ],
    );
    _documents.add(doc);
    return doc;
  }

  @override
  Future<List<Document>> listDocuments({String? folderId, String? query}) async {
    return _documents.where((doc) {
      if (folderId != null && doc.folderId != folderId) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final inName = doc.name.toLowerCase().contains(q);
        final inText = doc.pages
            .any((p) => (p.ocrText ?? '').toLowerCase().contains(q));
        if (!inName && !inText) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> renameDocument(String id, String name) async {
    final i = _documents.indexWhere((d) => d.id == id);
    if (i >= 0) _documents[i] = _documents[i].copyWith(name: name);
  }

  @override
  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> setPageOcr(String pageId, String text) async {
    for (var i = 0; i < _documents.length; i++) {
      final doc = _documents[i];
      final pages = [
        for (final page in doc.pages)
          page.id == pageId ? page.copyWith(ocrText: text) : page,
      ];
      _documents[i] = doc.copyWith(pages: pages);
    }
  }

  @override
  Future<Folder> createFolder(String name) async {
    final folder =
        Folder(id: _newId(), name: name, createdAt: DateTime.now());
    _folders.add(folder);
    return folder;
  }

  @override
  Future<List<Folder>> listFolders() async => List.of(_folders);

  @override
  Future<void> deleteFolder(String id) async {
    _folders.removeWhere((f) => f.id == id);
    for (var i = 0; i < _documents.length; i++) {
      if (_documents[i].folderId == id) {
        _documents[i] = _documents[i].copyWith(folderId: null);
      }
    }
  }

  @override
  Future<void> moveToFolder(String documentId, String? folderId) async {
    final i = _documents.indexWhere((d) => d.id == documentId);
    if (i >= 0) _documents[i] = _documents[i].copyWith(folderId: folderId);
  }
}
