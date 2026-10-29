import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/parsed_order.dart';
import 'package:brvm_portfolio/features/pdf_import/data/bici_bourse_order_parser.dart';
import 'package:brvm_portfolio/features/pdf_import/data/pdf_text_extractor.dart';

List<PdfLine> _loadFixture() {
  final file = File('test/fixtures/bici_ordre_achat_35968.lines.json');
  final json = jsonDecode(file.readAsStringSync()) as List;
  return json
      .map((e) => PdfLine(
            e['text'] as String,
            (e['y'] as num).toDouble(),
            [],
          ))
      .toList();
}

void main() {
  group('BiciBourseOrderParser', () {
    test('extrait fidèlement toutes les données de la fixture anonymisée', () {
      final lines = _loadFixture();
      final ordre = BiciBourseOrderParser.parse(lines);

      expect(ordre.sgi, equals('BICI BOURSE'));
      expect(ordre.sgiSlug, equals('bici_bourse'));
      expect(ordre.sens, equals(Sens.achat));
      expect(ordre.numeroOrdre, equals('35968'));
      expect(ordre.codeTitre, equals('SIBC'));
      expect(ordre.isin, equals('CI0000001871'));
      expect(ordre.libelle, equals('SIBC'));
      expect(ordre.quantite, equals(10));
      expect(ordre.typeCours, equals(TypeCours.limite));
      expect(ordre.prixLimite, equals(8700));
      expect(ordre.dateValidite, equals(DateTime.utc(2026, 10, 20)));
      expect(ordre.recuLe, equals(DateTime.utc(2026, 10, 20, 9, 58, 6)));
      expect(ordre.alertes.where((a) => a.severite == Severite.bloquant), isEmpty);
    });

    test('signale une alerte bloquante si la quantité est absente', () {
      final lines = _loadFixture().where((l) => !l.text.contains('Acheter')).toList();
      final ordre = BiciBourseOrderParser.parse(lines);

      expect(ordre.quantite, isNull);
      expect(ordre.alertes.any((a) => a.code == 'E_CHAMP_MANQUANT' && a.severite == Severite.bloquant), isTrue);
    });

    test('signale une alerte si le type de cours est inhabituel', () {
      final lines = _loadFixture().map((l) {
        if (l.text.contains('LIMITE')) {
          return PdfLine('Cours : AU MIEUX 8 700', l.y, l.words);
        }
        return l;
      }).toList();

      final ordre = BiciBourseOrderParser.parse(lines);
      expect(ordre.typeCours, equals(TypeCours.autre));
      expect(ordre.alertes.any((a) => a.code == 'W_TYPE_COURS_INCONNU'), isTrue);
    });

    test('émet une alerte d\'extraction partielle sur document vide', () {
      final ordre = BiciBourseOrderParser.parse([]);
      expect(ordre.numeroOrdre, isNull);
      expect(ordre.quantite, isNull);
      expect(ordre.alertes.any((a) => a.code == 'I_EXTRACTION_PARTIELLE'), isTrue);
    });
  });
}
