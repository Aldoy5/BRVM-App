import '../../../domain/models/parsed_order.dart';
import 'pdf_text_extractor.dart';

/// Centre vertical d'un mot.
double _cy(PdfWord w) => (w.y0 + w.y1) / 2;

/// Reconstruit des lignes logiques à partir de mots extraits d'un PDF.
/// Regroupe les mots par ordonnée centrale, avec une tolérance
/// relative à la hauteur médiane des mots.
List<PdfLine> buildLines(List<PdfWord> words) {
  if (words.isEmpty) return [];
  final h = words.map((w) => (w.y1 - w.y0).abs()).toList()..sort();
  final tol = h[h.length ~/ 2] * 0.6;
  final sorted = [...words]..sort((a, b) => _cy(a).compareTo(_cy(b)));
  final groups = <List<PdfWord>>[];

  for (final w in sorted) {
    if (groups.isNotEmpty && (_cy(w) - _cy(groups.last.first)).abs() <= tol) {
      groups.last.add(w);
    } else {
      groups.add([w]);
    }
  }

  return groups.map((g) {
    g.sort((a, b) => a.x0.compareTo(b.x0));
    return PdfLine(g.map((w) => w.text).join(' '), _cy(g.first), g);
  }).toList();
}

/// Supprime les accents courants pour fiabiliser la détection plein texte.
String _removeAccents(String s) {
  const accented = 'àâäéèêëïîôöùûüçÀÂÄÉÈÊËÏÎÔÖÙÛÜÇ';
  const plain = 'aaaeeeeiioouuucAAAEEEEIIOOUUUC';
  final buf = StringBuffer();
  for (final c in s.runes) {
    final ch = String.fromCharCode(c);
    final idx = accented.indexOf(ch);
    buf.write(idx >= 0 ? plain[idx] : ch);
  }
  return buf.toString();
}

/// Détecte le type de document à partir des lignes extraites.
/// Insensible à la casse, aux accents et aux variantes d'apostrophes.
TypeDocument detecterDocument(List<PdfLine> lines) {
  final fullText = _removeAccents(lines.map((l) => l.text).join(' ').toLowerCase());

  // Vérification de l'ordre d'achat BICI Bourse
  if (fullText.contains('bici bourse') &&
      (fullText.contains("ordre d'achat") ||
          fullText.contains("ordre d’achat") ||
          fullText.contains("ordre d.achat") ||
          fullText.contains("ordre dachat"))) {
    return TypeDocument.ordreAchat;
  }

  // Vérification de l'ordre de vente
  if (fullText.contains('ordre de vente')) {
    return TypeDocument.ordreVente;
  }

  // Vérification d'avis d'opéré
  if (fullText.contains("avis d'opere") ||
      fullText.contains("avis d’opere") ||
      fullText.contains("avis d.opere") ||
      fullText.contains("avis dopere") ||
      fullText.contains("avis d'execution") ||
      fullText.contains("avis d’execution") ||
      fullText.contains("avis dexecution")) {
    return TypeDocument.avisOpere;
  }

  return TypeDocument.inconnu;
}
