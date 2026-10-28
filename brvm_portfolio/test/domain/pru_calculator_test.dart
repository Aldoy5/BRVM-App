import 'package:test/test.dart';
import 'package:brvm_portfolio/domain/models/operation.dart';
import 'package:brvm_portfolio/domain/services/pru_calculator.dart';

void main() {
  const calculator = PruCalculator();

  group('PruCalculator - Achat simple', () {
    test('Achat simple sans frais : le PRU est égal au prix d\'achat', () {
      // 100 actions Sonatel à 10 000 FCFA sans frais
      final pru = calculator.calculerPruInitial(
        quantite: 100,
        prixAchat: 10000,
        frais: 0,
      );

      expect(pru, equals(10000));
    });

    test('Achat simple avec frais : le PRU intègre les frais dans le coût total', () {
      // 100 actions Sonatel à 10 000 FCFA avec 1 000 FCFA de frais
      // Coût total = 100 * 10 000 + 1 000 = 1 001 000 FCFA
      // PRU = 1 001 000 / 100 = 10 010 FCFA
      final pru = calculator.calculerPruInitial(
        quantite: 100,
        prixAchat: 10000,
        frais: 1000,
      );

      expect(pru, equals(10010));
    });

    test('Achat simple avec arrondi au FCFA entier le plus proche', () {
      // 3 actions à 1 000 FCFA avec 20 FCFA de frais
      // Coût total = 3 020 FCFA
      // 3 020 / 3 = 1006.666... => arrondi à 1007 FCFA
      final pru = calculator.calculerPruInitial(
        quantite: 3,
        prixAchat: 1000,
        frais: 20,
      );

      expect(pru, equals(1007));
    });
  });

  group('PruCalculator - Achats successifs (PRU moyen pondéré)', () {
    test('Deux achats successifs pondèrent le PRU', () {
      // 1er achat : 100 titres à 10 000 FCFA + 1 000 FCFA frais => PRU = 10 010 FCFA
      final pru1 = calculator.calculerPruInitial(
        quantite: 100,
        prixAchat: 10000,
        frais: 1000,
      );
      expect(pru1, equals(10010));

      // 2ème achat : 100 titres à 12 000 FCFA + 1 000 FCFA frais
      // Coût existant = 100 * 10 010 = 1 001 000 FCFA
      // Coût nouvel achat = 100 * 12 000 + 1 000 = 1 201 000 FCFA
      // Coût total = 2 202 000 FCFA pour 200 titres
      // Nouveau PRU = 2 202 000 / 200 = 11 010 FCFA
      final pru2 = calculator.calculerApresAchat(
        quantiteActuelle: 100,
        pruActuel: pru1,
        quantiteAchetee: 100,
        prixAchat: 12000,
        frais: 1000,
      );

      expect(pru2, equals(11010));
    });

    test('Deux achats avec quantités asymétriques', () {
      // 1er achat : 200 titres à 5 000 FCFA + 2 000 FCFA frais => coût = 1 002 000 FCFA, PRU = 5 010
      final pru1 = calculator.calculerPruInitial(
        quantite: 200,
        prixAchat: 5000,
        frais: 2000,
      );
      expect(pru1, equals(5010));

      // 2ème achat : 50 titres à 8 000 FCFA + 500 FCFA frais => coût = 400 500 FCFA
      // Coût total = (200 * 5010) + 400 500 = 1 002 000 + 400 500 = 1 402 500 FCFA
      // Quantité totale = 250 titres
      // PRU = 1 402 500 / 250 = 5 610 FCFA
      final pru2 = calculator.calculerApresAchat(
        quantiteActuelle: 200,
        pruActuel: pru1,
        quantiteAchetee: 50,
        prixAchat: 8000,
        frais: 500,
      );

      expect(pru2, equals(5610));
    });

    test('calculerPruGlobal retourne le même résultat que deux achats successifs', () {
      final pruGlobal = calculator.calculerPruGlobal([
        (quantite: 100, prix: 10000, frais: 1000),
        (quantite: 100, prix: 12000, frais: 1000),
      ]);

      expect(pruGlobal, equals(11010));
    });
  });

  group('PruCalculator - Ventes et conservation du PRU', () {
    test('Achat puis vente partielle : le PRU NE CHANGE PAS', () {
      const pruInitial = 10010;
      const quantiteActuelle = 100;

      final pruApresVente = calculator.calculerApresVente(
        pruActuel: pruInitial,
        quantiteActuelle: quantiteActuelle,
        quantiteVendue: 40,
      );

      expect(pruApresVente, equals(pruInitial));
    });

    test('Vente totale : le PRU reste conservé', () {
      const pruInitial = 10010;

      final pruApresVente = calculator.calculerApresVente(
        pruActuel: pruInitial,
        quantiteActuelle: 100,
        quantiteVendue: 100,
      );

      expect(pruApresVente, equals(pruInitial));
    });

    test('Vente totale puis rachat ultérieur (nouveau cycle d\'investissement)', () {
      // 1er cycle : achat 100 titres à 10 000 FCFA + 1 000 frais => PRU = 10 010
      // Vente totale des 100 titres => quantité = 0
      // 2ème cycle : rachat de 50 titres à 15 000 FCFA + 500 frais
      // Le nouveau PRU doit refléter uniquement le nouvel achat :
      // (50 * 15 000 + 500) / 50 = 750 500 / 50 = 15 010 FCFA
      final nouveauPru = calculator.calculerApresAchat(
        quantiteActuelle: 0,
        pruActuel: 10010,
        quantiteAchetee: 50,
        prixAchat: 15000,
        frais: 500,
      );

      expect(nouveauPru, equals(15010));
    });
  });

  group('PruCalculator - Plus-value réalisée sur vente', () {
    test('Plus-value réalisée positive (gain net)', () {
      // PRU = 10 000 FCFA. Vente de 50 titres à 12 000 FCFA avec 2 000 FCFA de frais
      // Produit net = 50 * 12 000 - 2 000 = 600 000 - 2 000 = 598 000 FCFA
      // Coût de revient = 50 * 10 000 = 500 000 FCFA
      // PV réalisée = 598 000 - 500 000 = +98 000 FCFA
      final pv = calculator.calculerPlusValueRealisee(
        pru: 10000,
        quantiteVendue: 50,
        prixVente: 12000,
        frais: 2000,
      );

      expect(pv, equals(98000));
    });

    test('Moins-value réalisée (perte avec frais)', () {
      // PRU = 10 000 FCFA. Vente de 50 titres à 9 000 FCFA avec 1 500 FCFA de frais
      // Produit net = 50 * 9 000 - 1 500 = 450 000 - 1 500 = 448 500 FCFA
      // Coût de revient = 50 * 10 000 = 500 000 FCFA
      // PV réalisée = 448 500 - 500 000 = -51 500 FCFA
      final pv = calculator.calculerPlusValueRealisee(
        pru: 10000,
        quantiteVendue: 50,
        prixVente: 9000,
        frais: 1500,
      );

      expect(pv, equals(-51500));
    });
  });

  group('PruCalculator - Replay d\'opérations', () {
    test('calculerPourOperations gère la séquence achat -> vente partielle -> achat', () {
      final now = DateTime(2026, 1, 1);
      final ops = [
        Operation.achat(
          id: '1',
          codeTitre: 'SNTS',
          quantite: 100,
          prixUnitaire: 10000,
          frais: const Frais(courtage: 1000),
          date: now,
        ),
        Operation.vente(
          id: '2',
          codeTitre: 'SNTS',
          quantite: 40,
          prixUnitaire: 12000,
          frais: const Frais(courtage: 500),
          date: now.add(const Duration(days: 1)),
        ),
        Operation.achat(
          id: '3',
          codeTitre: 'SNTS',
          quantite: 40,
          prixUnitaire: 11000,
          frais: const Frais(courtage: 500),
          date: now.add(const Duration(days: 2)),
        ),
      ];

      final res = calculator.calculerPourOperations(ops);

      // 1er achat : 100 titres, PRU = 10 010 FCFA
      // Vente 40 titres : reste 60 titres, PRU = 10 010 FCFA
      // PV réalisée = (40 * 12 000 - 500) - (40 * 10 010) = 479 500 - 400 400 = 79 100 FCFA
      // 2ème achat : 40 titres à 11 000 + 500 frais => coût = 440 500 FCFA
      // Coût existant (60 titres) = 60 * 10 010 = 600 600 FCFA
      // Coût total = 600 600 + 440 500 = 1 041 100 FCFA pour 100 titres
      // Nouveau PRU = 1 041 100 / 100 = 10 411 FCFA
      expect(res.quantite, equals(100));
      expect(res.pru, equals(10411));
      expect(res.pvRealisee, equals(79100));
    });
  });
}
