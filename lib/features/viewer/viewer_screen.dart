// Views a document's pages on a true black canvas, the way photo viewers do.
// A chip tracks the current page. Actions live in a bottom bar: recognize
// text (Pro, free users see the paywall), preview and print, share as PDF.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../core/result.dart';
import '../../core/theme.dart';
import '../../models/document.dart';
import '../../services/export_service.dart';
import '../../services/pdf_service.dart';
import '../../state/billing_controller.dart';
import '../../state/ocr_runner.dart';
import '../paywall/paywall_screen.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  int _page = 0;

  Document get document => widget.document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(document.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: document.pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => InteractiveViewer(
                child: Center(
                  child: Image.file(File(document.pages[i].imagePath)),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (document.pages.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_page + 1} / ${document.pages.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: BrandColors.textMid,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  _Action(
                    icon: Icons.text_fields,
                    label: 'Text',
                    onTap: () => _runOcr(context),
                  ),
                  _Action(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    onTap: () => _previewPdf(context),
                  ),
                  _Action(
                    icon: Icons.ios_share_outlined,
                    label: 'Share PDF',
                    onTap: () => _sharePdf(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// OCR is a Pro feature. Free users land on the paywall instead.
  Future<void> _runOcr(BuildContext context) async {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _buildPdf(BuildContext context) async {
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

  Future<void> _previewPdf(BuildContext context) async {
    final path = await _buildPdf(context);
    if (path == null) return;
    final bytes = await File(path).readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: document.name,
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final path = await _buildPdf(context);
    if (path == null) return;
    final shared = await ref
        .read(exportServiceProvider)
        .sharePdf(path, subject: document.name);
    if (shared case Err(message: final m)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(m)));
      }
    }
  }

  /// Document names are user text; keep them out of trouble as file names.
  String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: BrandColors.textHigh),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: BrandColors.textMid)),
            ],
          ),
        ),
      ),
    );
  }
}
