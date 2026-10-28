import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/operation.dart';
import 'package:brvm_portfolio/domain/services/portfolio_calculator.dart';
import 'package:brvm_portfolio/domain/services/reconciliation_service.dart';

void main() {
  const reconciliationService = ReconciliationService();
  const portfolioCalculator = PortfolioCalculator();
  final dateRef = DateTime(2026, 2, 1);

  group('ReconciliationService - Rapprochement de solde', () {
    test('Soldes identiques : écart nul et statut conforme', () {
      final operations = [
        Operation.depot(id: '1', montant: 1000000, date: dateRef),
      ];
      final portefeuille = portfolioCalculator.calculer(operations: operations);

      final ecart = reconciliationService.rapprocherSolde(
        portefeuille: portefeuille,
        soldeSgi: 1000000,
      );

      expect(ecart.ecart, equals(0));
      expect(ecart.estConforme, isTrue);
      expect(ecart.necessiteAjustement, isFalse);
    });

    test('Écart positif : la SGI affiche un solde supérieur (ex: dividende non enregistré)', () {
      final operations = [
        Operation.depot(id: '1', montant: 1000000, date: dateRef),
      ];
      final portefeuille = portfolioCalculator.calculer(operations: operations);

      // SGI affiche 1 050 000 FCFA
      final ecart = reconciliationService.rapprocherSolde(
        portefeuille: portefeuille,
        soldeSgi: 1050000,
      );

      expect(ecart.ecart, equals(50000));
      expect(ecart.estConforme, isFalse);
      expect(ecart.necessiteAjustement, isTrue);

      // Génération de l'opération d'ajustement
      final opAjustement = reconciliationService.creerOperationAjustement(
        id: 'ajust-1',
        ecart: ecart.ecart,
        date: dateRef.add(const Duration(days: 1)),
      );

      expect(opAjustement.type, equals(TypeOperation.ajustement));
      expect(opAjustement.montantNet, equals(50000));

      // Vérification que l'application de l'ajustement rétablit la conformité exacte
      final nouveauPortefeuille = portfolioCalculator.calculer(
        operations: [...operations, opAjustement],
      );
      expect(nouveauPortefeuille.soldeDisponible, equals(1050000));

      final verification = reconciliationService.rapprocherSolde(
        portefeuille: nouveauPortefeuille,
        soldeSgi: 1050000,
      );
      expect(verification.estConforme, isTrue);
      expect(verification.ecart, equals(0));
    });

    test('Écart négatif : la SGI affiche un solde inférieur (ex: frais de garde prélevés)', () {
      final operations = [
        Operation.depot(id: '1', montant: 1000000, date: dateRef),
      ];
      final portefeuille = portfolioCalculator.calculer(operations: operations);

      // SGI affiche 985 000 FCFA
      final ecart = reconciliationService.rapprocherSolde(
        portefeuille: portefeuille,
        soldeSgi: 985000,
      );

      expect(ecart.ecart, equals(-15000));
      expect(ecart.estConforme, isFalse);

      final opAjustement = reconciliationService.creerOperationAjustement(
        id: 'ajust-2',
        ecart: ecart.ecart,
        date: dateRef.add(const Duration(days: 1)),
      );

      expect(opAjustement.montantNet, equals(-15000));

      final nouveauPortefeuille = portfolioCalculator.calculer(
        operations: [...operations, opAjustement],
      );
      expect(nouveauPortefeuille.soldeDisponible, equals(985000));
    });
  });

  group('ReconciliationService - Rapprochement des lignes de titres', () {
    test('Détection des concordances et divergences de quantités de titres', () {
      final operations = [
        Operation.depot(id: '1', montant: 5000000, date: dateRef),
        Operation.achat(
          id: '2',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          date: dateRef.add(const Duration(days: 1)),
        ),
        Operation.achat(
          id: '3',
          codeTitre: 'ECOC',
          quantite: 50,
          prixUnitaire: 5000,
          date: dateRef.add(const Duration(days: 2)),
        ),
      ];

      final portefeuille = portfolioCalculator.calculer(operations: operations);

      // Relevé SGI :
      // SNTS : 100 (conforme)
      // ECOC : 60 (+10 titres reçus par attribution gratuite non saisie)
      // SGBC : 20 (titre acheté via la SGI sans saisie manuelle)
      final quantitesSgi = {
        'SNTS': 100,
        'ECOC': 60,
        'SGBC': 20,
      };

      final ecarts = reconciliationService.rapprocherTitres(
        portefeuille: portefeuille,
        quantitesSgi: quantitesSgi,
      );

      final ecartSnts = ecarts.firstWhere((e) => e.codeTitre == 'SNTS');
      expect(ecartSnts.estConforme, isTrue);
      expect(ecartSnts.ecartQuantite, equals(0));

      final ecartEcoc = ecarts.firstWhere((e) => e.codeTitre == 'ECOC');
      expect(ecartEcoc.estConforme, isFalse);
      expect(ecartEcoc.ecartQuantite, equals(10)); // 60 - 50 = +10

      final ecartSgbc = ecarts.firstWhere((e) => e.codeTitre == 'SGBC');
      expect(ecartSgbc.estConforme, isFalse);
      expect(ecartSgbc.quantiteCalculee, equals(0));
      expect(ecartSgbc.quantiteSgi, equals(20));
      expect(ecartSgbc.ecartQuantite, equals(20));
    });

    test('Rapprochement complet (espèces + titres)', () {
      final operations = [
        Operation.depot(id: '1', montant: 1000000, date: dateRef),
        Operation.achat(
          id: '2',
          codeTitre: 'SNTS',
          quantite: 50,
          prixUnitaire: 10000,
          date: dateRef.add(const Duration(days: 1)),
        ),
      ];

      final portefeuille = portfolioCalculator.calculer(operations: operations);

      // Cas 1 : Tout est conforme
      final rapportConforme = reconciliationService.rapprocherComplet(
        portefeuille: portefeuille,
        soldeSgi: 500000,
        quantitesSgi: {'SNTS': 50},
      );

      expect(rapportConforme.estEntierementConforme, isTrue);
      expect(rapportConforme.anomaliesTitres, isEmpty);

      // Cas 2 : Anomalie sur le solde et sur les titres
      final rapportAnomalie = reconciliationService.rapprocherComplet(
        portefeuille: portefeuille,
        soldeSgi: 480000, // -20 000 FCFA
        quantitesSgi: {'SNTS': 45}, // -5 titres
      );

      expect(rapportAnomalie.estEntierementConforme, isFalse);
      expect(rapportAnomalie.ecartSolde.ecart, equals(-20000));
      expect(rapportAnomalie.anomaliesTitres.length, equals(1));
      expect(rapportAnomalie.anomaliesTitres.first.ecartQuantite, equals(-5));
    });
  });
}
