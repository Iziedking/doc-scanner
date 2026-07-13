// Wraps: google_mlkit_text_recognition. On-device, offline after the model
// downloads on first use. Verify the API on pub.dev before shipping.

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/result.dart';

/// Runs OCR on a page image and returns the recognized text. Behind an
/// interface so it can be faked in tests and gated behind Pro in the UI.
abstract interface class OcrService {
  Future<Result<String>> recognize(String imagePath);
  void dispose();
}

class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<Result<String>> recognize(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(input);
      return Ok(result.text);
    } catch (e) {
      return Err('Text recognition failed.', cause: e);
    }
  }

  @override
  void dispose() => _recognizer.close();
}
