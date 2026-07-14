// Loads, adds, searches, and deletes documents, and manages folders. The
// library screen watches this. Built on flutter_riverpod 3.3.2, which replaced
// StateNotifier with Notifier (verified against the Riverpod 3 migration
// guide, 2026-07-13).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main() with the opened service.');
});

class LibraryState {
  const LibraryState({
    this.documents = const [],
    this.folders = const [],
    this.selectedFolderId,
    this.query = '',
    this.loading = false,
  });

  final List<Document> documents;
  final List<Folder> folders;

  /// Null means the All view: every document regardless of folder.
  final String? selectedFolderId;
  final String query;
  final bool loading;

  static const Object _unset = Object();

  LibraryState copyWith({
    List<Document>? documents,
    List<Folder>? folders,
    Object? selectedFolderId = _unset,
    String? query,
    bool? loading,
  }) =>
      LibraryState(
        documents: documents ?? this.documents,
        folders: folders ?? this.folders,
        selectedFolderId: identical(selectedFolderId, _unset)
            ? this.selectedFolderId
            : selectedFolderId as String?,
        query: query ?? this.query,
        loading: loading ?? this.loading,
      );
}

class LibraryController extends Notifier<LibraryState> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  LibraryState build() {
    // build() must return synchronously, so the first load is scheduled right
    // after it instead of awaited inside it.
    Future.microtask(refresh);
    return const LibraryState(loading: true);
  }

  Future<void> refresh() async {
    final folders = await _storage.listFolders();
    final docs = await _storage.listDocuments(
      folderId: state.selectedFolderId,
      query: state.query,
    );
    state = state.copyWith(documents: docs, folders: folders, loading: false);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, loading: true);
    await refresh();
  }

  Future<void> selectFolder(String? folderId) async {
    state = state.copyWith(selectedFolderId: folderId, loading: true);
    await refresh();
  }

  Future<Document> addFromScan(String name, List<String> imagePaths) async {
    final doc = await _storage.createDocument(
      name: name,
      scannedImagePaths: imagePaths,
      folderId: state.selectedFolderId,
    );
    await refresh();
    return doc;
  }

  Future<void> rename(String id, String name) async {
    await _storage.renameDocument(id, name);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _storage.deleteDocument(id);
    await refresh();
  }

  Future<void> createFolder(String name) async {
    final folder = await _storage.createFolder(name);
    state = state.copyWith(selectedFolderId: folder.id);
    await refresh();
  }

  Future<void> deleteFolder(String id) async {
    await _storage.deleteFolder(id);
    if (state.selectedFolderId == id) {
      state = state.copyWith(selectedFolderId: null);
    }
    await refresh();
  }

  Future<void> moveToFolder(String documentId, String? folderId) async {
    await _storage.moveToFolder(documentId, folderId);
    await refresh();
  }
}

final libraryProvider = NotifierProvider<LibraryController, LibraryState>(
  LibraryController.new,
);
