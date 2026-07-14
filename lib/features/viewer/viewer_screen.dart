// Views a document's pages. Actions: recognize text (Pro, free users see the
// paywall), preview and print, and share as PDF. The export reads the Pro flag
// so free exports carry a watermark and Pro exports do not.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../core/result.dart';
import '../../models/document.dart';
import '../../services/export_service.dart';
import '../../services/pdf_service.dart';
import '../../state/billing_controller.dart';
import '../../state/ocr_runner.dart';
import '../paywall/paywall_screen.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

class ViewerScreen extends ConsumerWidget {
  const ViewerScreen({super.key, required this.document});

  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Recognize text',
            onPressed: () => _runOcr(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Preview and print',
            onPressed: () => _previewPdf(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share as PDF',
            onPressed: () => _sharePdf(context, ref),
          ),
        ],
      ),
      body: PageView.builder(
        itemCount: document.pages.length,
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(child: Image.file(File(document.pages[i].imagePath))),
        ),
      ),
    );
  }

  /// OCR is a Pro feature. Free users land on the paywall instead.
  Future<void> _runOcr(BuildContext context, WidgetRef ref) async {
    final pro = ref.read(billingProvider);
    if (!pro) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    final result = await ref.read(ocrRunnerProvider).run(document);
    if (!context.mounted) return;
    final message = switch (result) {
      Ok(value: final pages) =>
        pages == 0 ? 'No text was found.' : 'Text saved. Search now covers it.',
      Err(message: final m) => m,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _buildPdf(BuildContext context, WidgetRef ref) async {
    final pro = ref.read(billingProvider);
    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path, '${_safeFileName(document.name)}.pdf');

    final built = await ref
        .read(pdfServiceProvider)
        .buildPdf(document: document, outputPath: out, pro: pro);
    switch (built) {
      case Err(message: final m):
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(m)));
        }
        return null;
      case Ok(value: final path):
        return path;
    }
  }

  Future<void> _previewPdf(BuildContext context, WidgetRef ref) async {
    final path = await _buildPdf(context, ref);
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: document.name,
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    final path = await _buildPdf(context, ref);
    if (path == null) return;
    final shared = await ref
        .read(exportServiceProvider)
        .sharePdf(path, subject: document.name);
    if (shared case Err(message: final m)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    }
  }

  /// Document names are user text; keep them out of trouble as file names.
  String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
}
