import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/cours.dart';
import 'package:brvm_portfolio/domain/models/operation.dart';
import 'package:brvm_portfolio/domain/services/portfolio_calculator.dart';

void main() {
  const calculator = PortfolioCalculator();
  final dateBase = DateTime(2026, 1, 10);

  group('PortfolioCalculator - Exigences Métier BRVM', () {
    // 1. Achat simple (calcul PRU avec frais)
    test('1. Achat simple : calcul exact du PRU avec frais et solde disponible', () {
      final operations = [
        Operation.depot(
          id: 'op-depot-1',
          montant: 1500000,
          date: dateBase,
        ),
        Operation.achat(
          id: 'op-achat-1',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          frais: const Frais(courtage: 800, commissions: 150, taxes: 50), // Total frais = 1 000
          date: dateBase.add(const Duration(days: 1)),
        ),
      ];

      // Cours du jour = 10 000 FCFA
      final cours = {
        'SNTS': Cours(
          codeTitre: 'SNTS',
          cloture: 10000,
          date: dateBase.add(const Duration(days: 1)),
        ),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      // Coût d'achat net décaissé : 100 * 10 000 + 1 000 = 1 001 000 FCFA
      // Solde disponible restant : 1 500 000 - 1 001 000 = 499 000 FCFA
      expect(portefeuille.soldeDisponible, equals(499000));

      final position = portefeuille.positionParCode('SNTS');
      expect(position, isNotNull);
      expect(position!.quantite, equals(100));
      // PRU = 1 001 000 / 100 = 10 010 FCFA
      expect(position.pru, equals(10010));
      // Valorisation ligne = 100 * 10 000 = 1 000 000 FCFA
      expect(position.valorisation, equals(1000000));
      // PV latente = 1 000 000 - (100 * 10 010) = -1 000 FCFA (perte latente égale aux frais engagés)
      expect(position.pvLatente, equals(-1000));
      // Valorisation totale = solde disponible + valo titre = 499 000 + 1 000 000 = 1 499 000 FCFA
      expect(portefeuille.valorisationTotale, equals(1499000));
    });

    // 2. Deux achats successifs (PRU pondéré)
    test('2. Deux achats successifs : PRU moyen pondéré exact', () {
      final operations = [
        Operation.depot(
          id: 'op-depot-1',
          montant: 3000000,
          date: dateBase,
        ),
        // Achat 1 : 100 titres à 10 000 FCFA + 1 000 FCFA de frais = 1 001 000 FCFA
        Operation.achat(
          id: 'op-achat-1',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          frais: const Frais(courtage: 1000),
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Achat 2 : 100 titres à 12 000 FCFA + 1 000 FCFA de frais = 1 201 000 FCFA
        Operation.achat(
          id: 'op-achat-2',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 12000,
          frais: const Frais(courtage: 1000),
          date: dateBase.add(const Duration(days: 2)),
        ),
      ];

      final cours = {
        'SNTS': Cours(
          codeTitre: 'SNTS',
          cloture: 12500,
          date: dateBase.add(const Duration(days: 2)),
        ),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      // Total décaissé = 1 001 000 + 1 201 000 = 2 202 000 FCFA
      // Solde restant = 3 000 000 - 2 202 000 = 798 000 FCFA
      expect(portefeuille.soldeDisponible, equals(798000));

      final position = portefeuille.positionParCode('SNTS')!;
      expect(position.quantite, equals(200));
      // PRU pondéré = (1 001 000 + 1 201 000) / 200 = 2 202 000 / 200 = 11 010 FCFA
      expect(position.pru, equals(11010));
      // Valorisation = 200 * 12 500 = 2 500 000 FCFA
      expect(position.valorisation, equals(2500000));
      // PV latente = 2 500 000 - (200 * 11 010) = 2 500 000 - 2 202 000 = +298 000 FCFA
      expect(position.pvLatente, equals(298000));
      // Valorisation totale = 798 000 + 2 500 000 = 3 298 000 FCFA
      expect(portefeuille.valorisationTotale, equals(3298000));
    });

    // 3. Achat puis vente partielle (PRU ne change pas)
    test('3. Achat puis vente partielle : le PRU NE CHANGE PAS et quantité diminue', () {
      final operations = [
        Operation.depot(
          id: 'op-depot-1',
          montant: 2000000,
          date: dateBase,
        ),
        // Achat 100 actions SNTS à 10 000 FCFA + 1 000 frais -> PRU = 10 010 FCFA
        Operation.achat(
          id: 'op-achat-1',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          frais: const Frais(courtage: 1000),
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Vente de 40 actions SNTS à 12 000 FCFA avec 500 FCFA de frais
        // Produit net de vente = 40 * 12 000 - 500 = 480 000 - 500 = 479 500 FCFA
        Operation.vente(
          id: 'op-vente-1',
          codeTitre: 'SNTS',
          quantite: 40,
          prixUnitaire: 12000,
          frais: const Frais(courtage: 500),
          date: dateBase.add(const Duration(days: 2)),
        ),
      ];

      final cours = {
        'SNTS': Cours(
          codeTitre: 'SNTS',
          cloture: 12000,
          date: dateBase.add(const Duration(days: 2)),
        ),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      // Solde disponible = 2 000 000 - 1 001 000 + 479 500 = 1 478 500 FCFA
      expect(portefeuille.soldeDisponible, equals(1478500));

      final position = portefeuille.positionParCode('SNTS')!;
      // Quantité résiduelle : 100 - 40 = 60
      expect(position.quantite, equals(60));
      // Le PRU NE CHANGE PAS : 10 010 FCFA
      expect(position.pru, equals(10010));

      // PV réalisée sur les 40 titres vendus :
      // 479 500 - (40 * 10 010) = 479 500 - 400 400 = +79 100 FCFA
      expect(position.pvRealisee, equals(79100));
      expect(portefeuille.pvRealisee, equals(79100));

      // PV latente sur les 60 titres restants :
      // 60 * 12 000 - (60 * 10 010) = 720 000 - 600 600 = +119 400 FCFA
      expect(position.pvLatente, equals(119400));
      expect(portefeuille.pvLatente, equals(119400));
    });

    // 4. Vente totale (ligne clôturée, PV réalisée)
    test('4. Vente totale : ligne clôturée (quantité = 0), PRU conservé, PV réalisée enregistrée', () {
      final operations = [
        Operation.depot(
          id: 'op-depot-1',
          montant: 500000,
          date: dateBase,
        ),
        // Achat 50 titres ECOC à 5 000 FCFA + 500 FCFA de frais = 250 500 FCFA
        // PRU = 250 500 / 50 = 5 010 FCFA
        Operation.achat(
          id: 'op-achat-1',
          codeTitre: 'ECOC',
          quantite: 50,
          prixUnitaire: 5000,
          frais: const Frais(courtage: 500),
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Vente de la totalité des 50 titres à 6 000 FCFA avec 500 FCFA de frais
        // Produit net = 50 * 6 000 - 500 = 299 500 FCFA
        Operation.vente(
          id: 'op-vente-1',
          codeTitre: 'ECOC',
          quantite: 50,
          prixUnitaire: 6000,
          frais: const Frais(courtage: 500),
          date: dateBase.add(const Duration(days: 2)),
        ),
      ];

      final portefeuille = calculator.calculer(operations: operations);

      // Solde disponible = 500 000 - 250 500 + 299 500 = 549 000 FCFA
      expect(portefeuille.soldeDisponible, equals(549000));
      expect(portefeuille.valorisationTotale, equals(549000));

      final position = portefeuille.positionParCode('ECOC')!;
      expect(position.quantite, equals(0));
      expect(position.estCloturee, isTrue);
      expect(position.estActive, isFalse);
      expect(position.pru, equals(5010)); // PRU conservé
      expect(position.valorisation, equals(0));
      expect(position.pvLatente, equals(0));

      // PV réalisée = 299 500 - (50 * 5 010) = 299 500 - 250 500 = +49 000 FCFA
      expect(position.pvRealisee, equals(49000));
      expect(portefeuille.pvRealisee, equals(49000));

      // Positions actives vs clôturées
      expect(portefeuille.positionsActives, isEmpty);
      expect(portefeuille.positionsCloturees.length, equals(1));
    });

    // 5. Dépôt et retrait (solde disponible)
    test('5. Dépôt et retrait : calcul exact de la trésorerie disponible', () {
      final operations = [
        Operation.depot(
          id: 'op-dep-1',
          montant: 1000000,
          date: dateBase,
        ),
        Operation.depot(
          id: 'op-dep-2',
          montant: 500000,
          date: dateBase.add(const Duration(days: 1)),
        ),
        Operation.retrait(
          id: 'op-ret-1',
          montant: 300000,
          date: dateBase.add(const Duration(days: 2)),
        ),
      ];

      final portefeuille = calculator.calculer(operations: operations);

      // Solde = 1 000 000 + 500 000 - 300 000 = 1 200 000 FCFA
      expect(portefeuille.soldeDisponible, equals(1200000));
      expect(portefeuille.valorisationTotale, equals(1200000));
      expect(portefeuille.positions, isEmpty);
      expect(portefeuille.pvTotale, equals(0));
      expect(portefeuille.pvJour, equals(0));
    });

    // 6. Ajustement (rapprochement)
    test('6. Ajustement : régularisation positive et négative de trésorerie', () {
      final operations = [
        Operation.depot(
          id: 'op-dep-1',
          montant: 1000000,
          date: dateBase,
        ),
        // Ajustement négatif (ex: prélèvement frais de garde semestriels SGI)
        Operation.ajustement(
          id: 'op-ajust-1',
          montant: -15000,
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Ajustement positif (ex: rattrapage dividende net)
        Operation.ajustement(
          id: 'op-ajust-2',
          montant: 25000,
          date: dateBase.add(const Duration(days: 2)),
        ),
      ];

      final portefeuille = calculator.calculer(operations: operations);

      // Solde = 1 000 000 - 15 000 + 25 000 = 1 010 000 FCFA
      expect(portefeuille.soldeDisponible, equals(1010000));
      expect(portefeuille.valorisationTotale, equals(1010000));
    });

    // 7. Portefeuille vide
    test('7. Portefeuille vide : tous les soldes et valorisations sont nuls', () {
      final portefeuille = calculator.calculer(operations: []);

      expect(portefeuille.soldeDisponible, equals(0));
      expect(portefeuille.valorisationTotale, equals(0));
      expect(portefeuille.pvJour, equals(0));
      expect(portefeuille.pvTotale, equals(0));
      expect(portefeuille.pvLatente, equals(0));
      expect(portefeuille.pvRealisee, equals(0));
      expect(portefeuille.positions, isEmpty);
      expect(portefeuille.positionsActives, isEmpty);
      expect(portefeuille.positionsCloturees, isEmpty);
    });

    // 8. Plusieurs titres différents
    test('8. Plusieurs titres différents : calcul indépendant des positions et agrégation', () {
      final operations = [
        Operation.depot(
          id: 'depot',
          montant: 5000000,
          date: dateBase,
        ),
        // Titre 1 : SNTS (100 * 15 000 + 1 500 frais = 1 501 500 FCFA, PRU = 15 015)
        Operation.achat(
          id: 'achat-snts',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 15000,
          frais: const Frais(courtage: 1500),
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Titre 2 : ECOC (200 * 5 000 + 1 000 frais = 1 001 000 FCFA, PRU = 5 005)
        Operation.achat(
          id: 'achat-ecoc',
          codeTitre: 'ECOC',
          quantite: 200,
          prixUnitaire: 5000,
          frais: const Frais(courtage: 1000),
          date: dateBase.add(const Duration(days: 2)),
        ),
        // Titre 3 : SGBC (50 * 18 000 + 1 000 frais = 901 000 FCFA, PRU = 18 020)
        Operation.achat(
          id: 'achat-sgbc',
          codeTitre: 'SGBC',
          quantite: 50,
          prixUnitaire: 18000,
          frais: const Frais(courtage: 1000),
          date: dateBase.add(const Duration(days: 3)),
        ),
      ];

      final cours = {
        'SNTS': Cours(codeTitre: 'SNTS', cloture: 16000, date: dateBase.add(const Duration(days: 4))),
        'ECOC': Cours(codeTitre: 'ECOC', cloture: 5500, date: dateBase.add(const Duration(days: 4))),
        'SGBC': Cours(codeTitre: 'SGBC', cloture: 17500, date: dateBase.add(const Duration(days: 4))),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      // Solde disponible = 5 000 000 - (1 501 500 + 1 001 000 + 901 000)
      //                  = 5 000 000 - 3 403 500 = 1 596 500 FCFA
      expect(portefeuille.soldeDisponible, equals(1596500));

      final posSnts = portefeuille.positionParCode('SNTS')!;
      expect(posSnts.quantite, equals(100));
      expect(posSnts.pru, equals(15015));
      expect(posSnts.valorisation, equals(1600000));
      expect(posSnts.pvLatente, equals(1600000 - (100 * 15015))); // 1 600 000 - 1 501 500 = +98 500

      final posEcoc = portefeuille.positionParCode('ECOC')!;
      expect(posEcoc.quantite, equals(200));
      expect(posEcoc.pru, equals(5005));
      expect(posEcoc.valorisation, equals(1100000));
      expect(posEcoc.pvLatente, equals(1100000 - (200 * 5005))); // 1 100 000 - 1 001 000 = +99 000

      final posSgbc = portefeuille.positionParCode('SGBC')!;
      expect(posSgbc.quantite, equals(50));
      expect(posSgbc.pru, equals(18020));
      expect(posSgbc.valorisation, equals(875000));
      expect(posSgbc.pvLatente, equals(875000 - (50 * 18020))); // 875 000 - 901 000 = -26 000

      // Valorisation titres = 1 600 000 + 1 100 000 + 875 000 = 3 575 000 FCFA
      expect(portefeuille.valorisationTitres, equals(3575000));

      // Valorisation totale = 1 596 500 + 3 575 000 = 5 171 500 FCFA
      expect(portefeuille.valorisationTotale, equals(5171500));
    });

    // 9. Variation du jour
    test('9. Variation du jour : calcul exact de la variation quotidienne par ligne et consolidée', () {
      final operations = [
        Operation.depot(
          id: 'depot',
          montant: 5000000,
          date: dateBase,
        ),
        Operation.achat(
          id: 'achat-snts',
          codeTitre: 'SNTS',
          quantite: 50,
          prixUnitaire: 14000,
          date: dateBase.add(const Duration(days: 1)),
        ),
        Operation.achat(
          id: 'achat-ecoc',
          codeTitre: 'ECOC',
          quantite: 100,
          prixUnitaire: 6000,
          date: dateBase.add(const Duration(days: 1)),
        ),
      ];

      // Cours du jour avec cours de la veille :
      // SNTS : clôture 15 000 FCFA, veille 14 500 FCFA (+500 FCFA / action)
      // ECOC : clôture 5 800 FCFA, veille 6 000 FCFA (-200 FCFA / action)
      final cours = {
        'SNTS': Cours(
          codeTitre: 'SNTS',
          cloture: 15000,
          coursVeille: 14500,
          date: dateBase.add(const Duration(days: 2)),
        ),
        'ECOC': Cours(
          codeTitre: 'ECOC',
          cloture: 5800,
          coursVeille: 6000,
          date: dateBase.add(const Duration(days: 2)),
        ),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      final posSnts = portefeuille.positionParCode('SNTS')!;
      // 50 * (15 000 - 14 500) = 50 * 500 = +25 000 FCFA
      expect(posSnts.variationJour, equals(25000));

      final posEcoc = portefeuille.positionParCode('ECOC')!;
      // 100 * (5 800 - 6 000) = 100 * (-200) = -20 000 FCFA
      expect(posEcoc.variationJour, equals(-20000));

      // Variation globale = 25 000 + (-20 000) = +5 000 FCFA
      expect(portefeuille.pvJour, equals(5000));
    });

    // 10. Plus-value totale (latente + réalisée)
    test('10. Plus-value totale : somme exacte de la PV latente et de la PV réalisée', () {
      final operations = [
        Operation.depot(
          id: 'depot',
          montant: 5000000,
          date: dateBase,
        ),
        // Titre 1 (SNTS) : Achat 100 à 10 000 FCFA (coût 1 000 000 FCFA, PRU = 10 000 FCFA)
        Operation.achat(
          id: 'achat-snts',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          date: dateBase.add(const Duration(days: 1)),
        ),
        // Vente de 50 SNTS à 13 000 FCFA sans frais
        // Produit = 50 * 13 000 = 650 000 FCFA
        // Coût = 50 * 10 000 = 500 000 FCFA
        // PV réalisée sur SNTS = 650 000 - 500 000 = +150 000 FCFA
        Operation.vente(
          id: 'vente-snts',
          codeTitre: 'SNTS',
          quantite: 50,
          prixUnitaire: 13000,
          date: dateBase.add(const Duration(days: 2)),
        ),
        // Titre 2 (ECOC) : Achat 100 à 5 000 FCFA (coût 500 000 FCFA, PRU = 5 000 FCFA)
        Operation.achat(
          id: 'achat-ecoc',
          codeTitre: 'ECOC',
          quantite: 100,
          prixUnitaire: 5000,
          date: dateBase.add(const Duration(days: 3)),
        ),
      ];

      // Cours du marché :
      // SNTS à 14 000 FCFA : 50 restants, valo = 700 000, PV latente = 700 000 - (50 * 10 000) = +200 000 FCFA
      // ECOC à 4 500 FCFA : 100 détenus, valo = 450 000, PV latente = 450 000 - (100 * 5 000) = -50 000 FCFA
      final cours = {
        'SNTS': Cours(codeTitre: 'SNTS', cloture: 14000, date: dateBase.add(const Duration(days: 4))),
        'ECOC': Cours(codeTitre: 'ECOC', cloture: 4500, date: dateBase.add(const Duration(days: 4))),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      // PV latente totale = 200 000 + (-50 000) = +150 000 FCFA
      expect(portefeuille.pvLatente, equals(150000));

      // PV réalisée totale = +150 000 FCFA
      expect(portefeuille.pvRealisee, equals(150000));

      // Plus-value totale = latente + réalisée = 150 000 + 150 000 = +300 000 FCFA
      expect(portefeuille.pvTotale, equals(300000));
    });

    // Test additionnel : Tri chronologique automatique
    test('Tri chronologique automatique lorsque les opérations sont désordonnées', () {
      final op1 = Operation.depot(
        id: '1',
        montant: 1000000,
        date: dateBase,
      );
      final op2 = Operation.achat(
        id: '2',
        codeTitre: 'SNTS',
        quantite: 50,
        prixUnitaire: 10000,
        date: dateBase.add(const Duration(days: 1)),
      );
      final op3 = Operation.vente(
        id: '3',
        codeTitre: 'SNTS',
        quantite: 50,
        prixUnitaire: 12000,
        date: dateBase.add(const Duration(days: 2)),
      );

      // Fournies dans le désordre : op3, op1, op2
      final portefeuille = calculator.calculer(operations: [op3, op1, op2]);

      expect(portefeuille.soldeDisponible, equals(1100000));
      expect(portefeuille.pvRealisee, equals(100000));
      expect(portefeuille.positionParCode('SNTS')!.quantite, equals(0));
    });

    // Test additionnel : Insensibilité à la casse des symboles
    test('Recherche insensible à la casse sur les codes de titres', () {
      final operations = [
        Operation.depot(id: '1', montant: 1000000, date: dateBase),
        Operation.achat(
          id: '2',
          codeTitre: 'snts', // Minuscule
          quantite: 10,
          prixUnitaire: 10000,
          date: dateBase.add(const Duration(days: 1)),
        ),
      ];

      final cours = {
        'SNTS': Cours(codeTitre: 'SNTS', cloture: 12000, date: dateBase.add(const Duration(days: 2))),
      };

      final portefeuille = calculator.calculer(
        operations: operations,
        derniersCours: cours,
      );

      final pos = portefeuille.positionParCode('SNTS');
      expect(pos, isNotNull);
      expect(pos!.quantite, equals(10));
      expect(pos.dernierCours, equals(12000));
      expect(pos.valorisation, equals(120000));
    });
  });
}
