import 'dart:typed_data';

/// Un mot extrait d'un PDF avec ses coordonnées géométriques (bounding box).
class PdfWord {
  /// Texte du mot.
  final String text;

  /// Coordonnées du rectangle englobant (y orienté de haut en bas).
  final double x0, y0, x1, y1;

  const PdfWord(this.text, this.x0, this.y0, this.x1, this.y1);

  @override
  String toString() => 'PdfWord("$text", x0: $x0, y0: $y0, x1: $x1, y1: $y1)';
}

/// Une ligne de texte reconstruite à partir de mots regroupés par ordonnée.
class PdfLine {
  /// Texte concaténé de la ligne.
  final String text;

  /// Ordonnée centrale médiane de la ligne.
  final double y;

  /// Mots individuels composant la ligne, triés de gauche à droite.
  final List<PdfWord> words;

  const PdfLine(this.text, this.y, this.words);

  @override
  String toString() => 'PdfLine(y: ${y.toStringAsFixed(1)}, "$text")';
}

/// Interface d'extraction de texte depuis un fichier PDF.
/// Découplée de toute implémentation tierce (pdfrx, syncfusion, etc.).
abstract class PdfTextExtractor {
  /// Extrait tous les mots du PDF avec leurs coordonnées normalisées.
  Future<List<PdfWord>> extractWords(Uint8List bytes);
}
