// Wraps: share_plus 13.2.0, verified on pub.dev 2026-07-13. The old static
// Share.shareXFiles is deprecated; the current call is
// SharePlus.instance.share(ShareParams(...)).

import 'package:share_plus/share_plus.dart';

import '../core/result.dart';

class ExportService {
  Future<Result<void>> sharePdf(String pdfPath, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(pdfPath)], subject: subject),
      );
      return const Ok(null);
    } catch (e) {
      return Err('Sharing failed.', cause: e);
    }
  }
}
