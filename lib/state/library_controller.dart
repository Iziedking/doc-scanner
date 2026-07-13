// Loads, adds, searches, and deletes documents. The library screen watches this.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in main() with the opened service.');
});

class LibraryState {
  const LibraryState({this.documents = const [], this.query = '', this.loading = false});
  final List<Document> documents;
  final String query;
  final bool loading;

  LibraryState copyWith({List<Document>? documents, String? query, bool? loading}) =>
      LibraryState(
        documents: documents ?? this.documents,
        query: query ?? this.query,
        loading: loading ?? this.loading,
      );
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._storage) : super(const LibraryState()) {
    refresh();
  }

  final StorageService _storage;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    final docs = await _storage.listDocuments(query: state.query);
    state = state.copyWith(documents: docs, loading: false);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    await refresh();
  }

  Future<Document> addFromScan(String name, List<String> imagePaths) async {
    final doc = await _storage.createDocument(name: name, scannedImagePaths: imagePaths);
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
}

final libraryProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(ref.watch(storageServiceProvider));
});
