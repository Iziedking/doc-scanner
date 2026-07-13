/// One scanned page. The image lives as a file on disk; this holds its path,
/// its order in the document, and the OCR text once it has been recognized.
class DocPage {
  const DocPage({
    required this.id,
    required this.documentId,
    required this.imagePath,
    required this.order,
    this.ocrText,
  });

  final String id;
  final String documentId;
  final String imagePath;
  final int order;
  final String? ocrText;

  DocPage copyWith({String? ocrText, int? order}) => DocPage(
        id: id,
        documentId: documentId,
        imagePath: imagePath,
        order: order ?? this.order,
        ocrText: ocrText ?? this.ocrText,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'document_id': documentId,
        'image_path': imagePath,
        'ocr_text': ocrText,
        'page_order': order,
      };

  factory DocPage.fromRow(Map<String, Object?> row) => DocPage(
        id: row['id']! as String,
        documentId: row['document_id']! as String,
        imagePath: row['image_path']! as String,
        order: row['page_order']! as int,
        ocrText: row['ocr_text'] as String?,
      );
}
