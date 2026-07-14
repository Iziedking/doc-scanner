// Wraps: flutter_doc_scanner 0.0.21 (ML Kit on Android, VisionKit on iOS).
// Verified against the plugin source on 2026-07-13. In this version
// getScannedDocumentAsImages returns a typed ImageScanResult with the page
// image paths, and failures throw DocScanException with a machine-readable
// code, including CANCELLED when the user backs out of the platform UI.

import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

import '../core/result.dart';

/// What came back from the platform scan UI. Cancelling is a normal outcome,
/// not an error, so it gets its own case instead of an Err.
sealed class ScanOutcome {
  const ScanOutcome();
}

class ScanPages extends ScanOutcome {
  const ScanPages(this.imagePaths);

  /// Page image file paths in scan order. The app copies these into its own
  /// directory right away; the scanner's cache can be cleaned by the OS.
  final List<String> imagePaths;
}

class ScanCancelled extends ScanOutcome {
  const ScanCancelled();
}

/// A thin interface so the UI never touches the plugin, and tests can fake it.
abstract interface class ScannerService {
  Future<Result<ScanOutcome>> scan({required int pageLimit});
}

class MlKitScannerService implements ScannerService {
  @override
  Future<Result<ScanOutcome>> scan({required int pageLimit}) async {
    try {
      final result = await FlutterDocScanner().getScannedDocumentAsImages(
        page: pageLimit,
      );
      final paths = result?.images ?? const <String>[];
      if (paths.isEmpty) {
        return const Ok(ScanCancelled());
      }
      return Ok(ScanPages(paths));
    } on DocScanException catch (e) {
      if (e.code == DocScanException.codeCancelled) {
        return const Ok(ScanCancelled());
      }
      // ML Kit refuses to run on devices under about 1.7 GB RAM and reports
      // UNSUPPORTED. Surface that plainly so the UI can explain it.
      final unsupported = e.code == DocScanException.codeUnsupported ||
          e.message.contains('UNSUPPORTED');
      return Err(
        unsupported
            ? 'This device does not meet the scanner requirements.'
            : 'The scan could not be completed.',
        cause: e,
      );
    } catch (e) {
      return Err('The scan could not be completed.', cause: e);
    }
  }
}
