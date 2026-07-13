// Views a document's pages and exports a PDF. The export reads the Pro flag so
// free exports carry a watermark and Pro exports do not.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/result.dart';
import '../../models/document.dart';
import '../../services/export_service.dart';
import '../../services/pdf_service.dart';
import '../../state/billing_controller.dart';

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
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(context, ref),
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

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final pro = ref.read(billingProvider);
    final dir = await getTemporaryDirectory();
    final out = p.join(dir.path, '${document.name}.pdf');

    final built = await PdfService()
        .buildPdf(document: document, outputPath: out, pro: pro);
    if (built case Err(message: final m)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
      return;
    }
    if (built case Ok(value: final path)) {
      await ExportService().sharePdf(path, subject: document.name);
    }
  }
}
