import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/parsed_order.dart';
import 'package:brvm_portfolio/domain/services/order_validator.dart';

ParsedOrder _makeOrder({
  String? numeroOrdre = '35968',
  Sens? sens = Sens.achat,
  int? quantite = 10,
  String? codeTitre = 'SIBC',
  int? prixLimite = 8700,
  DateTime? dateValidite,
  DateTime? recuLe,
}) =>
    ParsedOrder(
      sgi: 'BICI BOURSE',
      sgiSlug: 'bici_bourse',
      numeroOrdre: numeroOrdre,
      sens: sens,
      quantite: quantite,
      codeTitre: codeTitre,
      isin: 'CI0000001871',
      libelle: 'SIBC',
      typeCours: TypeCours.limite,
      prixLimite: prixLimite,
      dateValidite: dateValidite ?? DateTime.utc(2099, 12, 31),
      recuLe: recuLe ?? DateTime.utc(2026, 10, 20, 9, 58, 6),
    );

void main() {
  group('OrderValidator - validerImportOrdre', () {
    test('détecte un doublon si l\'ordre a déjà été enregistré', () {
      final ordre = _makeOrder();
      final ctx = ValidationContext(
        operationIdsExistants: {'bici_bourse_35968'},
        codesTitresConnus: {'SIBC'},
      );

      final alertes = validerImportOrdre(ordre, ctx);
      expect(alertes.any((a) => a.code == 'E_DOUBLON' && a.severite == Severite.bloquant), isTrue);
    });

    test('bloque si la quantité est absente ou inférieure à 1', () {
      final ordreSansQte = _makeOrder(quantite: null);
      final alertes1 = validerImportOrdre(ordreSansQte, const ValidationContext());
      expect(alertes1.any((a) => a.code == 'E_CHAMP_MANQUANT'), isTrue);

      final ordreQteZero = _makeOrder(quantite: 0);
      final alertes2 = validerImportOrdre(ordreQteZero, const ValidationContext());
      expect(alertes2.any((a) => a.code == 'E_QTE_HORS_BORNES'), isTrue);
    });

    test('bloque si le titre ou le sens est manquant', () {
      final ordreSansTitre = _makeOrder(codeTitre: null);
      final alertes1 = validerImportOrdre(ordreSansTitre, const ValidationContext());
      expect(alertes1.any((a) => a.code == 'E_CHAMP_MANQUANT'), isTrue);

      final ordreSansSens = _makeOrder(sens: null);
      final alertes2 = validerImportOrdre(ordreSansSens, const ValidationContext());
      expect(alertes2.any((a) => a.code == 'E_CHAMP_MANQUANT'), isTrue);
    });

    test('émet une alerte si le titre est inconnu du référentiel marché', () {
      final ordre = _makeOrder(codeTitre: 'INCONNU');
      final ctx = const ValidationContext(codesTitresConnus: {'SIBC', 'SNTS'});
      final alertes = validerImportOrdre(ordre, ctx);
      expect(alertes.any((a) => a.code == 'W_TITRE_INCONNU'), isTrue);
    });

    test('signale un ordre expiré', () {
      final ordre = _makeOrder(dateValidite: DateTime.utc(2020, 1, 1));
      final ctx = ValidationContext(dateReference: DateTime.utc(2026, 1, 1));
      final alertes = validerImportOrdre(ordre, ctx);
      expect(alertes.any((a) => a.code == 'W_ORDRE_EXPIRE'), isTrue);
    });

    test('signale une extraction partielle si un champ optionnel est absent', () {
      final ordre = _makeOrder(prixLimite: null);
      final alertes = validerImportOrdre(ordre, const ValidationContext());
      expect(alertes.any((a) => a.code == 'I_EXTRACTION_PARTIELLE'), isTrue);
    });

    test('valide un ordre complet sans alerte bloquante', () {
      final ordre = _makeOrder();
      final ctx = const ValidationContext(codesTitresConnus: {'SIBC'});
      final alertes = validerImportOrdre(ordre, ctx);
      expect(alertes.where((a) => a.severite == Severite.bloquant), isEmpty);
    });
  });

  group('OrderValidator - vérifications ponctuelles', () {
    test('verifierPrixLimite bloque si le prix exécuté dépasse la limite', () {
      final depasse = verifierPrixLimite(prixSaisi: 9000, prixLimite: 8700);
      expect(depasse, isNotNull);
      expect(depasse!.code, equals('E_PRIX_SUP_LIMITE'));

      final conforme = verifierPrixLimite(prixSaisi: 8700, prixLimite: 8700);
      expect(conforme, isNull);
    });

    test('verifierDateFenetre alerte si date hors période', () {
      final avant = verifierDateFenetre(
        date: DateTime.utc(2026, 10, 19),
        recuLe: DateTime.utc(2026, 10, 20),
        dateValidite: DateTime.utc(2026, 10, 25),
      );
      expect(avant?.code, equals('W_DATE_HORS_FENETRE'));

      final apres = verifierDateFenetre(
        date: DateTime.utc(2026, 10, 26),
        recuLe: DateTime.utc(2026, 10, 20),
        dateValidite: DateTime.utc(2026, 10, 25),
      );
      expect(apres?.code, equals('W_DATE_HORS_FENETRE'));

      final dansFenetre = verifierDateFenetre(
        date: DateTime.utc(2026, 10, 22),
        recuLe: DateTime.utc(2026, 10, 20),
        dateValidite: DateTime.utc(2026, 10, 25),
      );
      expect(dansFenetre, isNull);
    });
  });
}
