import '../models/operation.dart';

/// Service de calcul du Prix de Revient Unitaire (PRU) moyen pondéré
/// et des plus-values réalisées pour les titres de la BRVM.
/// Tous les calculs s'effectuent en entiers FCFA (arrondi au FCFA le plus proche).
class PruCalculator {
  const PruCalculator();

  /// Calcule le PRU initial d'une nouvelle ligne lors du tout premier achat.
  /// Formule : (quantité × prixAchat + frais) ÷ quantité
  int calculerPruInitial({
    required int quantite,
    required int prixAchat,
    int frais = 0,
  }) {
    if (quantite <= 0) return 0;
    final coutTotal = (quantite * prixAchat) + frais;
    return (coutTotal / quantite).round();
  }

  /// Calcule le nouveau PRU pondéré après un achat renforçant une position existante.
  /// Formule : ((quantitéActuelle × pruActuel) + (quantitéAchetée × prixAchat + frais))
  ///           ÷ (quantitéActuelle + quantitéAchetée)
  ///
  /// Si la position était vide ou clôturée (quantitéActuelle <= 0),
  /// le PRU est calculé uniquement sur le nouvel achat (nouveau cycle).
  int calculerApresAchat({
    required int quantiteActuelle,
    required int pruActuel,
    required int quantiteAchetee,
    required int prixAchat,
    int frais = 0,
  }) {
    if (quantiteAchetee <= 0) return pruActuel;

    if (quantiteActuelle <= 0) {
      return calculerPruInitial(
        quantite: quantiteAchetee,
        prixAchat: prixAchat,
        frais: frais,
      );
    }

    final coutExistant = quantiteActuelle * pruActuel;
    final coutNouvelAchat = (quantiteAchetee * prixAchat) + frais;
    final nouvelleQuantite = quantiteActuelle + quantiteAchetee;

    if (nouvelleQuantite <= 0) return 0;
    return ((coutExistant + coutNouvelAchat) / nouvelleQuantite).round();
  }

  /// Retourne le PRU après une vente (partielle ou totale).
  /// RÈGLE MÉTIER BRVM : À la vente, le PRU ne change JAMAIS.
  /// Seule la quantité en portefeuille diminue.
  int calculerApresVente({
    required int pruActuel,
    required int quantiteActuelle,
    required int quantiteVendue,
  }) {
    // Le PRU reste inchangé quelle que soit la quantité vendue.
    return pruActuel;
  }

  /// Calcule la plus-value ou moins-value réalisée lors d'une cession de titres.
  /// Formule : (prix_vente × qté - frais_vente) - (PRU × qté_vendue)
  int calculerPlusValueRealisee({
    required int pru,
    required int quantiteVendue,
    required int prixVente,
    int frais = 0,
  }) {
    if (quantiteVendue <= 0) return 0;
    final produitNetVente = (quantiteVendue * prixVente) - frais;
    final coutRevient = quantiteVendue * pru;
    return produitNetVente - coutRevient;
  }

  /// Calcule le PRU moyen pondéré global pour une liste d'achats purs.
  /// Formule : (somme des coûts d'achat + frais) ÷ somme des quantités achetées
  int calculerPruGlobal(List<({int quantite, int prix, int frais})> achats) {
    if (achats.isEmpty) return 0;

    int totalCout = 0;
    int totalQuantite = 0;

    for (final achat in achats) {
      if (achat.quantite > 0) {
        totalCout += (achat.quantite * achat.prix) + achat.frais;
        totalQuantite += achat.quantite;
      }
    }

    if (totalQuantite <= 0) return 0;
    return (totalCout / totalQuantite).round();
  }

  /// Rejoue une liste chronologique d'opérations d'un titre pour déterminer
  /// son PRU final et sa quantité restante.
  ({int quantite, int pru, int pvRealisee}) calculerPourOperations(
    List<Operation> operations,
  ) {
    int quantite = 0;
    int pru = 0;
    int pvRealisee = 0;

    final opsTriees = List<Operation>.of(operations)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final op in opsTriees) {
      if (op.type == TypeOperation.achat) {
        pru = calculerApresAchat(
          quantiteActuelle: quantite,
          pruActuel: pru,
          quantiteAchetee: op.quantite,
          prixAchat: op.prixUnitaire,
          frais: op.frais.total,
        );
        quantite += op.quantite;
      } else if (op.type == TypeOperation.vente) {
        pvRealisee += calculerPlusValueRealisee(
          pru: pru,
          quantiteVendue: op.quantite,
          prixVente: op.prixUnitaire,
          frais: op.frais.total,
        );
        quantite -= op.quantite;
        if (quantite < 0) quantite = 0;
        // Le PRU ne change pas
      }
    }

    return (quantite: quantite, pru: pru, pvRealisee: pvRealisee);
  }
}
