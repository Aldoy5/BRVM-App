import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'pdf_text_extractor.dart';

/// Implémentation concrète de l'extracteur PDF basée sur `syncfusion_flutter_pdf`.
/// Extrait les mots géométriques et le texte des pages d'un PDF vectoriel numérique.
class SyncfusionPdfTextExtractor implements PdfTextExtractor {
  @override
  Future<List<PdfWord>> extractWords(Uint8List bytes) async {
    sf.PdfDocument? document;
    try {
      document = sf.PdfDocument(inputBytes: bytes);
      final extractor = sf.PdfTextExtractor(document);
      final textLines = extractor.extractTextLines();

      final words = <PdfWord>[];
      for (final line in textLines) {
        for (final word in line.wordCollection) {
          if (word.text.trim().isEmpty) continue;
          words.add(PdfWord(
            word.text.trim(),
            word.bounds.left,
            word.bounds.top,
            word.bounds.right,
            word.bounds.bottom,
          ));
        }
      }
      return words;
    } catch (_) {
      return <PdfWord>[];
    } finally {
      document?.dispose();
    }
  }

  /// Extraction directe de texte plein page par page.
  Future<String> extractFullText(Uint8List bytes) async {
    sf.PdfDocument? document;
    try {
      document = sf.PdfDocument(inputBytes: bytes);
      final extractor = sf.PdfTextExtractor(document);
      return extractor.extractText();
    } catch (_) {
      return '';
    } finally {
      document?.dispose();
    }
  }
}
