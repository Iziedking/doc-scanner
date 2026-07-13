// Wraps: pdf + printing. Builds a PDF from a document's page images. Free
// exports carry a small footer watermark; Pro exports skip it.
// Verify pdf and printing APIs on pub.dev before shipping.

import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/result.dart';
import '../models/document.dart';

class PdfService {
  /// Assemble the document into a PDF file on disk and return its path.
  /// [pro] removes the watermark.
  Future<Result<String>> buildPdf({
    required Document document,
    required String outputPath,
    required bool pro,
  }) async {
    try {
      final pdf = pw.Document();

      for (final page in document.pages) {
        final bytes = await File(page.imagePath).readAsBytes();
        final image = pw.MemoryImage(bytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              final content = pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
              if (pro) return content;
              return pw.Stack(
                children: [
                  content,
                  pw.Positioned(
                    bottom: 8,
                    right: 8,
                    child: pw.Text(
                      'Scanned with DocScan',
                      style: pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey500),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
      return Ok(file.path);
    } catch (e) {
      return Err('The PDF could not be created.', cause: e);
    }
  }
}
