import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/services/frais_calculator.dart';

void main() {
  group('FraisCalculator - parseFcfa', () {
    test('parse les entiers avec séparateurs d\'espaces ou de virgules', () {
      expect(parseFcfa('8,700'), equals(8700));
      expect(parseFcfa('8 700'), equals(8700));
      expect(parseFcfa('8700'), equals(8700));
      expect(parseFcfa('125 000 500'), equals(125000500));
      // Espace insécable (char code 160)
      expect(parseFcfa('8\u00A0700'), equals(8700));
    });

    test('rejette les formats invalides ou décimaux incomplets', () {
      expect(parseFcfa('8,70'), isNull);
      expect(parseFcfa('abc'), isNull);
      expect(parseFcfa(''), isNull);
    });
  });

  group('FraisCalculator - parseDateFr', () {
    test('parse les dates valides au format jj/mm/aaaa', () {
      final d = parseDateFr('20/10/2026');
      expect(d, equals(DateTime.utc(2026, 10, 20)));
    });

    test('rejette les dates inexistantes ou formats invalides', () {
      expect(parseDateFr('31/02/2026'), isNull);
      expect(parseDateFr('00/01/2026'), isNull);
      expect(parseDateFr('1/1/2026'), isNull);
      expect(parseDateFr('2026-10-20'), isNull);
      expect(parseDateFr(''), isNull);
    });
  });

  group('FraisCalculator - calculerFrais', () {
    test('respecte la table de calcul contractuelle', () {
      // brut, tauxBp, attendu
      expect(calculerFrais(brut: 87000, tauxBp: 118), equals(1027));
      expect(calculerFrais(brut: 87000, tauxBp: 140), equals(1218));
      expect(calculerFrais(brut: 86500, tauxBp: 118), equals(1021));
      expect(calculerFrais(brut: 100, tauxBp: 118), equals(1));
      expect(calculerFrais(brut: 357, tauxBp: 118), equals(4));
      expect(calculerFrais(brut: 0, tauxBp: 118), equals(0));
    });

    test('garantit que les frais restent toujours positifs ou nuls', () {
      expect(calculerFrais(brut: 1, tauxBp: 118), greaterThanOrEqualTo(0));
    });
  });

  group('FraisCalculator - parseTauxBp', () {
    test('convertit les chaînes décimales en points de base', () {
      expect(parseTauxBp('1,18'), equals(118));
      expect(parseTauxBp('1.18'), equals(118));
      expect(parseTauxBp('1,40'), equals(140));
      expect(parseTauxBp('1.4'), equals(140));
      expect(parseTauxBp('0'), equals(0));
    });

    test('rejette les taux négatifs ou hors limites', () {
      expect(parseTauxBp('-1'), isNull);
      expect(parseTauxBp('11'), isNull);
      expect(parseTauxBp('abc'), isNull);
    });
  });

  group('FraisCalculator - net et PRU', () {
    test('calcule le montant net d\'un achat', () {
      expect(montantNetAchat(87000, 1027), equals(88027));
    });

    test('calcule le PRU unitaire affiché arrondi', () {
      expect(prixRevientAffiche(88027, 10), equals(8803));
      expect(prixRevientAffiche(88027, 0), equals(0));
    });
  });
}
