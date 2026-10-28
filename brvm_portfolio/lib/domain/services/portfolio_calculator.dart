import '../models/cours.dart';
import '../models/operation.dart';
import '../models/portefeuille.dart';
import '../models/position.dart';
import 'pru_calculator.dart';

/// Structure interne temporaire servant à accumuler l'état d'un titre
/// au fil du replay chronologique des opérations.
class _LigneAccumulateur {
  int quantite = 0;
  int pru = 0;
  int pvRealisee = 0;
  int fraisCumules = 0;
  int quantiteAchetee = 0;
  int quantiteVendue = 0;
}

/// Service pur de calcul du portefeuille BRVM.
/// Recalcule l'intégralité du portefeuille à partir de la source de vérité :
/// le journal des opérations, complété par les derniers cours de marché.
///
/// Cette classe est pure et sans effet de bord (side-effects).
class PortfolioCalculator {
  final PruCalculator pruCalculator;

  const PortfolioCalculator({
    this.pruCalculator = const PruCalculator(),
  });

  /// Calcule l'état consolidé du portefeuille à partir de la liste des opérations
  /// et des derniers cours connus.
  ///
  /// Traite systématiquement les opérations dans l'ordre chronologique.
  Portefeuille calculer({
    required List<Operation> operations,
    Map<String, Cours> derniersCours = const {},
  }) {
    if (operations.isEmpty) {
      return Portefeuille.vide();
    }

    // 1. Tri chronologique stable du journal des opérations
    final operationsTriees = List<Operation>.of(operations);
    operationsTriees.sort((a, b) => a.date.compareTo(b.date));

    // 2. Accumulateurs d'état de trésorerie et de frais
    int soldeDisponible = 0;
    int pvRealiseeTotale = 0;
    int fraisTotaux = 0;

    // Table de suivi de chaque titre par son symbole (clé en majuscule)
    final Map<String, _LigneAccumulateur> accumulateurs = {};
    // Conserve le code exact tel que saisi initialement
    final Map<String, String> codesOriginaux = {};

    // 3. Replay chronologique des opérations
    for (final op in operationsTriees) {
      fraisTotaux += op.frais.total;

      switch (op.type) {
        case TypeOperation.depot:
          // Montant crédité sur le compte de liquidités
          soldeDisponible += op.montantNet;
          break;

        case TypeOperation.retrait:
          // Montant débité du compte de liquidités
          soldeDisponible -= op.montantNet;
          break;

        case TypeOperation.ajustement:
          // Régularisation de trésorerie (positive ou négative)
          soldeDisponible += op.montantNet;
          break;

        case TypeOperation.achat:
          if (op.codeTitre == null) continue;
          final codeCle = op.codeTitre!.trim().toUpperCase();
          codesOriginaux.putIfAbsent(codeCle, () => op.codeTitre!.trim());

          final acc = accumulateurs.putIfAbsent(
            codeCle,
            () => _LigneAccumulateur(),
          );

          // Impact de trésorerie : décaissement net (prix × qté + frais)
          final coutAchatNet = (op.quantite * op.prixUnitaire) + op.frais.total;
          soldeDisponible -= coutAchatNet;

          // Mise à jour de la ligne de titre
          acc.pru = pruCalculator.calculerApresAchat(
            quantiteActuelle: acc.quantite,
            pruActuel: acc.pru,
            quantiteAchetee: op.quantite,
            prixAchat: op.prixUnitaire,
            frais: op.frais.total,
          );
          acc.quantite += op.quantite;
          acc.quantiteAchetee += op.quantite;
          acc.fraisCumules += op.frais.total;
          break;

        case TypeOperation.vente:
          if (op.codeTitre == null) continue;
          final codeCle = op.codeTitre!.trim().toUpperCase();
          codesOriginaux.putIfAbsent(codeCle, () => op.codeTitre!.trim());

          final acc = accumulateurs.putIfAbsent(
            codeCle,
            () => _LigneAccumulateur(),
          );

          // Impact de trésorerie : encaissement net (prix × qté - frais)
          final produitVenteNet =
              (op.quantite * op.prixUnitaire) - op.frais.total;
          soldeDisponible += produitVenteNet;

          // Calcul de la plus-value réalisée : (produit net) - (PRU × qté vendue)
          final pvVente = pruCalculator.calculerPlusValueRealisee(
            pru: acc.pru,
            quantiteVendue: op.quantite,
            prixVente: op.prixUnitaire,
            frais: op.frais.total,
          );

          acc.pvRealisee += pvVente;
          pvRealiseeTotale += pvVente;

          // Diminution de la quantité (le PRU ne change PAS)
          acc.quantite -= op.quantite;
          if (acc.quantite < 0) {
            acc.quantite = 0;
          }
          acc.quantiteVendue += op.quantite;
          acc.fraisCumules += op.frais.total;
          break;
      }
    }

    // 4. Construction des positions consolidées avec valorisation de marché
    final List<Position> positionsCalculees = [];

    // Normalisation de la table des cours pour recherche insensible à la casse
    final Map<String, Cours> coursNormalises = {};
    derniersCours.forEach((cle, cours) {
      coursNormalises[cle.trim().toUpperCase()] = cours;
    });

    for (final entry in accumulateurs.entries) {
      final codeCle = entry.key;
      final acc = entry.value;
      final codeTitre = codesOriginaux[codeCle] ?? codeCle;

      final cours = coursNormalises[codeCle];
      final int dernierPrix;
      final int? coursVeille;

      if (cours != null) {
        dernierPrix = cours.cloture;
        coursVeille = cours.coursVeille;
      } else {
        // En l'absence de cours, on retient le PRU pour ne pas biaiser la PV latente
        dernierPrix = acc.pru;
        coursVeille = acc.pru;
      }

      final position = Position.calculer(
        codeTitre: codeTitre,
        quantite: acc.quantite,
        pru: acc.pru,
        dernierCours: dernierPrix,
        coursVeille: coursVeille,
        pvRealisee: acc.pvRealisee,
        fraisCumules: acc.fraisCumules,
        quantiteAchetee: acc.quantiteAchetee,
        quantiteVendue: acc.quantiteVendue,
      );

      positionsCalculees.add(position);
    }

    // 5. Agrégation et production du Portefeuille final
    return Portefeuille.calculer(
      positions: positionsCalculees,
      soldeDisponible: soldeDisponible,
      pvRealisee: pvRealiseeTotale,
      fraisTotaux: fraisTotaux,
    );
  }
}
