// Wraps: flutter_doc_scanner (ML Kit on Android, VisionKit on iOS).
// Built against README as of this plan. VERIFY the current method names and the
// result shape on https://pub.dev/packages/flutter_doc_scanner before shipping,
// because this plugin's surface has changed between releases.

import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

import '../core/result.dart';

/// The outcome of a scan: the page image file paths in order. The plugin can
/// also return a ready-made PDF, but I keep the images so the app owns page
/// order, OCR, and re-export rather than depending on the plugin's PDF.
class ScanOutcome {
  const ScanOutcome(this.imagePaths);
  final List<String> imagePaths;
}

/// A thin interface so the UI never touches the plugin, and tests can fake it.
abstract interface class ScannerService {
  Future<Result<ScanOutcome>> scan({required int pageLimit});
}

class MlKitScannerService implements ScannerService {
  @override
  Future<Result<ScanOutcome>> scan({required int pageLimit}) async {
    try {
      // The plugin returns a platform-specific payload. On Android with ML Kit
      // it exposes page image uris and a pdf uri. Read image paths from it.
      // NOTE: confirm the exact getter names against the installed version.
      final dynamic raw = await FlutterDocScanner().getScannedDocumentAsImages(
        page: pageLimit,
      );

      final paths = _extractImagePaths(raw);
      if (paths.isEmpty) {
        return const Err('No pages were returned from the scanner.');
      }
      return Ok(ScanOutcome(paths));
    } catch (e) {
      // A common real failure: the device has under 1.7 GB RAM and ML Kit
      // reports UNSUPPORTED. Surface it plainly so the UI can explain it.
      final message = e.toString().contains('UNSUPPORTED')
          ? 'This device does not meet the scanner requirements.'
          : 'The scan could not be completed.';
      return Err(message, cause: e);
    }
  }

  /// Normalize the plugin payload into a plain list of file paths. The plugin
  /// has returned images under a few shapes across versions, so handle them.
  List<String> _extractImagePaths(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is Map) {
      final images = raw['images'] ?? raw['Uri'] ?? raw['imageUris'];
      if (images is List) {
        return images.map((e) => e.toString()).toList();
      }
      final single = raw['pdfUri'] ?? raw['uri'];
      if (single != null) return [single.toString()];
    }
    return const [];
  }
}
