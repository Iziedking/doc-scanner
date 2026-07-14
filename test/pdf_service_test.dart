// The PDF service builds from real image files, so the test generates a tiny
// JPEG with package:image. The free-versus-Pro branch is the point: the free
// build carries the watermark, the Pro build does not.

import 'dart:io';

import 'package:docscan/core/result.dart';
import 'package:docscan/models/doc_page.dart';
import 'package:docscan/models/document.dart';
import 'package:docscan/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('docscan_pdf_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<Document> documentWithPages(int count) async {
    final pages = <DocPage>[];
    for (var i = 0; i < count; i++) {
      final image = img.Image(width: 60, height: 80);
      img.fill(image, color: img.ColorRgb8(240, 240, 240));
      final path = p.join(tempDir.path, 'page_$i.jpg');
      await File(path).writeAsBytes(img.encodeJpg(image));
      pages.add(DocPage(
        id: 'page-$i',
        documentId: 'doc-1',
        imagePath: path,
        order: i,
      ));
    }
    final now = DateTime.now();
    return Document(
      id: 'doc-1',
      name: 'Test doc',
      createdAt: now,
      updatedAt: now,
      pages: pages,
    );
  }

  test('builds a PDF file from page images', () async {
    final doc = await documentWithPages(2);
    final out = p.join(tempDir.path, 'out.pdf');

    final result = await PdfService()
        .buildPdf(document: doc, outputPath: out, pro: true);

    expect(result, isA<Ok<String>>());
    final bytes = await File(out).readAsBytes();
    expect(bytes, isNotEmpty);
    // Every PDF starts with this header. A cheap sanity check that the file
    // is what it claims to be.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('free build carries the watermark, Pro build does not', () async {
    final doc = await documentWithPages(1);
    final freeOut = p.join(tempDir.path, 'free.pdf');
    final proOut = p.join(tempDir.path, 'pro.pdf');

    final free = await PdfService()
        .buildPdf(document: doc, outputPath: freeOut, pro: false);
    final pro = await PdfService()
        .buildPdf(document: doc, outputPath: proOut, pro: true);

    expect(free, isA<Ok<String>>());
    expect(pro, isA<Ok<String>>());

    final freeBytes = await File(freeOut).readAsBytes();
    final proBytes = await File(proOut).readAsBytes();
    expect(freeBytes.length, greaterThan(proBytes.length),
        reason: 'the watermark text and its font add content');
  });

  test('a missing page image comes back as Err, not a crash', () async {
    final now = DateTime.now();
    final doc = Document(
      id: 'doc-x',
      name: 'Broken',
      createdAt: now,
      updatedAt: now,
      pages: const [
        DocPage(
          id: 'page-x',
          documentId: 'doc-x',
          imagePath: 'does_not_exist.jpg',
          order: 0,
        ),
      ],
    );

    final result = await PdfService().buildPdf(
      document: doc,
      outputPath: p.join(tempDir.path, 'broken.pdf'),
      pro: true,
    );
    expect(result, isA<Err<String>>());
  });
}
