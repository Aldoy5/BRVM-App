import '../models/operation.dart';
import '../models/portefeuille.dart';

/// Résultat du rapprochement du solde de trésorerie avec la SGI.
class EcartSolde {
  /// Solde disponible calculé par le portefeuille en FCFA.
  final int soldeCalcule;

  /// Solde réel officiel transmis par la SGI en FCFA.
  final int soldeSgi;

  /// Écart constaté en FCFA (soldeSgi - soldeCalcule).
  /// Un montant positif indique un excédent chez la SGI (fonds supplémentaires).
  /// Un montant négatif indique un déficit chez la SGI (frais prélevés, etc.).
  final int ecart;

  /// Indique si les soldes sont parfaitement équilibrés (écart nul).
  bool get estConforme => ecart == 0;

  /// Indique si une opération d'ajustement est nécessaire.
  bool get necessiteAjustement => ecart != 0;

  const EcartSolde({
    required this.soldeCalcule,
    required this.soldeSgi,
    required this.ecart,
  });

  @override
  String toString() {
    return 'EcartSolde(calculé: $soldeCalcule FCFA, SGI: $soldeSgi FCFA, écart: $ecart FCFA)';
  }
}

/// Écart constaté sur une ligne de titre entre le portefeuille et la SGI.
class EcartTitre {
  /// Code mnémonique du titre (ex: "SNTS").
  final String codeTitre;

  /// Quantité calculée actuellement en portefeuille.
  final int quantiteCalculee;

  /// Quantité officielle constatée sur le relevé SGI.
  final int quantiteSgi;

  /// Différence de quantité (quantiteSgi - quantiteCalculee).
  int get ecartQuantite => quantiteSgi - quantiteCalculee;

  /// Indique si la quantité est conforme entre les deux sources.
  bool get estConforme => ecartQuantite == 0;

  const EcartTitre({
    required this.codeTitre,
    required this.quantiteCalculee,
    required this.quantiteSgi,
  });

  @override
  String toString() {
    return 'EcartTitre($codeTitre: calculé=$quantiteCalculee, SGI=$quantiteSgi, écart=$ecartQuantite)';
  }
}

/// Rapport consolidé de rapprochement global (espèces et titres).
class RapportReconciliation {
  /// Résultat du contrôle de solde d'espèces.
  final EcartSolde ecartSolde;

  /// Écarts éventuels sur les lignes de titres.
  final List<EcartTitre> ecartsTitres;

  /// Date et heure de réalisation du rapprochement.
  final DateTime dateRapprochement;

  /// Indique si l'ensemble du portefeuille est parfaitement en phase avec la SGI.
  bool get estEntierementConforme =>
      ecartSolde.estConforme && ecartsTitres.every((e) => e.estConforme);

  /// Liste des écarts de titres non résolus.
  List<EcartTitre> get anomaliesTitres =>
      ecartsTitres.where((e) => !e.estConforme).toList(growable: false);

  const RapportReconciliation({
    required this.ecartSolde,
    required this.ecartsTitres,
    required this.dateRapprochement,
  });

  @override
  String toString() {
    return 'RapportReconciliation(conforme: $estEntierementConforme, '
        'solde: ${ecartSolde.ecart} FCFA, '
        'anomaliesTitres: ${anomaliesTitres.length})';
  }
}

/// Service de rapprochement comptable entre le portefeuille local
/// et les relevés de compte officiels transmis par la SGI.
class ReconciliationService {
  const ReconciliationService();

  /// Compare le solde de trésorerie disponible avec le solde officiel de la SGI.
  EcartSolde rapprocherSolde({
    required Portefeuille portefeuille,
    required int soldeSgi,
  }) {
    final soldeCalcule = portefeuille.soldeDisponible;
    final ecart = soldeSgi - soldeCalcule;

    return EcartSolde(
      soldeCalcule: soldeCalcule,
      soldeSgi: soldeSgi,
      ecart: ecart,
    );
  }

  /// Génère une opération d'ajustement [TypeOperation.ajustement] pour régulariser
  /// le solde de trésorerie avec la SGI.
  ///
  /// L'opération générée a pour montant l'écart comptable. Une fois ajoutée au journal,
  /// elle remettra le solde disponible au niveau exact du solde SGI.
  Operation creerOperationAjustement({
    required String id,
    required int ecart,
    required DateTime date,
    String? referenceSgi,
    String? commentaire,
  }) {
    return Operation.ajustement(
      id: id,
      montant: ecart,
      date: date,
      referenceSgi: referenceSgi,
      commentaire: commentaire ??
          'Régularisation suite à rapprochement SGI (écart: $ecart FCFA)',
    );
  }

  /// Compare les quantités de titres détenues avec le relevé de compte de la SGI.
  List<EcartTitre> rapprocherTitres({
    required Portefeuille portefeuille,
    required Map<String, int> quantitesSgi,
  }) {
    final List<EcartTitre> ecarts = [];

    // Normalisation des codes SGI en majuscules
    final Map<String, int> sgiNormalise = {};
    quantitesSgi.forEach((code, qte) {
      sgiNormalise[code.trim().toUpperCase()] = qte;
    });

    final Set<String> codesTraites = {};

    // 1. Analyse des positions actives ou historisées locales
    for (final pos in portefeuille.positions) {
      final codeCle = pos.codeTitre.trim().toUpperCase();
      codesTraites.add(codeCle);

      final qteSgi = sgiNormalise[codeCle] ?? 0;
      ecarts.add(EcartTitre(
        codeTitre: pos.codeTitre,
        quantiteCalculee: pos.quantite,
        quantiteSgi: qteSgi,
      ));
    }

    // 2. Détection des titres présents chez la SGI mais inconnus en local
    for (final entry in sgiNormalise.entries) {
      if (!codesTraites.contains(entry.key)) {
        ecarts.add(EcartTitre(
          codeTitre: entry.key,
          quantiteCalculee: 0,
          quantiteSgi: entry.value,
        ));
      }
    }

    return ecarts;
  }

  /// Exécute un rapprochement complet combiné (solde de trésorerie + lignes de titres).
  RapportReconciliation rapprocherComplet({
    required Portefeuille portefeuille,
    required int soldeSgi,
    Map<String, int> quantitesSgi = const {},
    DateTime? date,
  }) {
    final ecartSolde = rapprocherSolde(
      portefeuille: portefeuille,
      soldeSgi: soldeSgi,
    );

    final ecartsTitres = quantitesSgi.isNotEmpty
        ? rapprocherTitres(
            portefeuille: portefeuille,
            quantitesSgi: quantitesSgi,
          )
        : <EcartTitre>[];

    return RapportReconciliation(
      ecartSolde: ecartSolde,
      ecartsTitres: ecartsTitres,
      dateRapprochement: date ?? DateTime.now(),
    );
  }
}
