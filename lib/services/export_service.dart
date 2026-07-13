// Wraps: share_plus. Hands a finished PDF or image to the system share sheet.
// Verify the share_plus API on pub.dev before shipping.

import 'package:share_plus/share_plus.dart';

import '../core/result.dart';

class ExportService {
  Future<Result<void>> sharePdf(String pdfPath, {String? subject}) async {
    try {
      await Share.shareXFiles([XFile(pdfPath)], subject: subject);
      return const Ok(null);
    } catch (e) {
      return Err('Sharing failed.', cause: e);
    }
  }
}
