// Runs text recognition over a document's pages and stores the text on each
// page row, which makes the document findable by content search. Pro-only;
// the gate lives in the UI so this stays a plain worker.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../models/document.dart';
import '../services/ocr_service.dart';
import '../services/storage_service.dart';
import 'library_controller.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = MlKitOcrService();
  ref.onDispose(service.dispose);
  return service;
});

final ocrRunnerProvider = Provider<OcrRunner>((ref) {
  return OcrRunner(
    ref.watch(ocrServiceProvider),
    ref.watch(storageServiceProvider),
  );
});

class OcrRunner {
  const OcrRunner(this._ocr, this._storage);

  final OcrService _ocr;
  final StorageService _storage;

  /// Recognize every page and save the text. Returns how many pages produced
  /// text, or the first failure. Stops at the first error rather than half
  /// finishing quietly.
  Future<Result<int>> run(Document document) async {
    var pagesWithText = 0;
    for (final page in document.pages) {
      final result = await _ocr.recognize(page.imagePath);
      switch (result) {
        case Err(message: final message, cause: final cause):
          return Err(message, cause: cause);
        case Ok(value: final text):
          await _storage.setPageOcr(page.id, text);
          if (text.trim().isNotEmpty) pagesWithText++;
      }
    }
    return Ok(pagesWithText);
  }
}
