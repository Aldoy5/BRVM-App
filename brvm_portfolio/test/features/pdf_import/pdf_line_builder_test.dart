import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/parsed_order.dart';
import 'package:brvm_portfolio/features/pdf_import/data/pdf_line_builder.dart';
import 'package:brvm_portfolio/features/pdf_import/data/pdf_text_extractor.dart';

void main() {
  group('PdfLineBuilder - buildLines', () {
    test('renvoie une liste vide si aucun mot fourni', () {
      expect(buildLines([]), isEmpty);
    });

    test('regroupe les mots alignés horizontalement sur une même ligne', () {
      final words = [
        const PdfWord('ORDRE', 10, 98, 40, 108),
        const PdfWord("D'ACHAT", 45, 99, 90, 109),
        const PdfWord('N°', 95, 98, 110, 108),
        const PdfWord('35968', 115, 97, 150, 107),
      ];
      final lines = buildLines(words);
      expect(lines.length, equals(1));
      expect(lines.first.text, equals("ORDRE D'ACHAT N° 35968"));
    });

    test('trie les mots de gauche à droite sur une même ligne', () {
      final words = [
        const PdfWord('BICI', 10, 50, 30, 60),
        const PdfWord('BOURSE', 35, 50, 80, 60),
      ];
      // Dans le désordre
      final disordered = [words[1], words[0]];
      final lines = buildLines(disordered);
      expect(lines.first.text, equals('BICI BOURSE'));
    });

    test('sépare les lignes ayant des ordonnées distinctes et les trie verticalement', () {
      final words = [
        const PdfWord('Ligne 2', 10, 100, 50, 110),
        const PdfWord('Ligne 1', 10, 20, 50, 30),
      ];
      final lines = buildLines(words);
      expect(lines.length, equals(2));
      expect(lines[0].text, equals('Ligne 1'));
      expect(lines[1].text, equals('Ligne 2'));
    });
  });

  group('PdfLineBuilder - detecterDocument', () {
    test('reconnaît un ordre d\'achat BICI Bourse', () {
      final lines = [
        const PdfLine('BICI BOURSE', 50, []),
        const PdfLine("ORDRE D'ACHAT N° 35968", 100, []),
      ];
      expect(detecterDocument(lines), equals(TypeDocument.ordreAchat));
    });

    test('gère les variations typographiques et d\'accents pour l\'ordre d\'achat', () {
      final lines = [
        const PdfLine('bici bourse sgi', 50, []),
        const PdfLine('ordre d’achat n° 1234', 100, []),
      ];
      expect(detecterDocument(lines), equals(TypeDocument.ordreAchat));
    });

    test('reconnaît un ordre de vente', () {
      final lines = [
        const PdfLine('BICI BOURSE', 50, []),
        const PdfLine('ORDRE DE VENTE N° 9999', 100, []),
      ];
      expect(detecterDocument(lines), equals(TypeDocument.ordreVente));
    });

    test('reconnaît un avis d\'opéré', () {
      final lines = [
        const PdfLine('SGI AFRICA', 50, []),
        const PdfLine("AVIS D'OPÉRÉ DU 20/10/2026", 100, []),
      ];
      expect(detecterDocument(lines), equals(TypeDocument.avisOpere));
    });

    test('retourne inconnu pour un document quelconque', () {
      final lines = [
        const PdfLine('Relevé bancaire trimestriel', 50, []),
        const PdfLine('Solde créditeur au 31/12/2026', 100, []),
      ];
      expect(detecterDocument(lines), equals(TypeDocument.inconnu));
    });
  });
}
