import 'position.dart';

/// Représente l'état global consolidé d'un portefeuille boursier BRVM.
/// Tous les montants monétaires sont des entiers FCFA.
class Portefeuille {
  /// Ensemble des positions (ouvertes et clôturées) du portefeuille.
  final List<Position> positions;

  /// Solde de trésorerie disponible en FCFA sur le compte de la SGI :
  /// dépôts - retraits - achats (frais inclus) + ventes (nettes de frais) ± ajustements.
  final int soldeDisponible;

  /// Valorisation globale du portefeuille en FCFA :
  /// soldeDisponible + somme des valorisations des lignes d'actions actives.
  final int valorisationTotale;

  /// Variation de valeur globale sur la séance de cotation du jour en FCFA :
  /// somme des variations journalières de chaque ligne active.
  final int pvJour;

  /// Plus-value totale du portefeuille en FCFA :
  /// somme des plus-values latentes (positions actives) + somme des plus-values réalisées (ventes).
  final int pvTotale;

  /// Plus-value ou moins-value latente cumulée sur les positions actuellement ouvertes en FCFA.
  final int pvLatente;

  /// Plus-value ou moins-value réalisée cumulée sur l'ensemble des cessions en FCFA.
  final int pvRealisee;

  /// Total cumulé de tous les frais payés (achats, ventes, opérations diverses) en FCFA.
  final int fraisTotaux;

  const Portefeuille({
    required this.positions,
    required this.soldeDisponible,
    required this.valorisationTotale,
    required this.pvJour,
    required this.pvTotale,
    this.pvLatente = 0,
    this.pvRealisee = 0,
    this.fraisTotaux = 0,
  });

  /// Crée une instance de portefeuille entièrement vide avec soldes nuls.
  factory Portefeuille.vide() {
    return const Portefeuille(
      positions: [],
      soldeDisponible: 0,
      valorisationTotale: 0,
      pvJour: 0,
      pvTotale: 0,
      pvLatente: 0,
      pvRealisee: 0,
      fraisTotaux: 0,
    );
  }

  /// Construit un portefeuille en agrégeant automatiquement les métriques de positions.
  factory Portefeuille.calculer({
    required List<Position> positions,
    required int soldeDisponible,
    int pvRealisee = 0,
    int fraisTotaux = 0,
  }) {
    final positionsActives = positions.where((p) => p.estActive);

    final valorisationTitres = positionsActives.fold<int>(
      0,
      (sum, p) => sum + p.valorisation,
    );

    final pvLatenteTotale = positionsActives.fold<int>(
      0,
      (sum, p) => sum + p.pvLatente,
    );

    final pvJourTotale = positionsActives.fold<int>(
      0,
      (sum, p) => sum + p.variationJour,
    );

    final valorisationTotale = soldeDisponible + valorisationTitres;
    final pvTotale = pvLatenteTotale + pvRealisee;

    return Portefeuille(
      positions: List.unmodifiable(positions),
      soldeDisponible: soldeDisponible,
      valorisationTotale: valorisationTotale,
      pvJour: pvJourTotale,
      pvTotale: pvTotale,
      pvLatente: pvLatenteTotale,
      pvRealisee: pvRealisee,
      fraisTotaux: fraisTotaux,
    );
  }

  /// Liste des positions actuellement en portefeuille (quantité > 0).
  List<Position> get positionsActives =>
      positions.where((p) => p.estActive).toList(growable: false);

  /// Liste des positions historisées ayant été entièrement soldées (quantité == 0).
  List<Position> get positionsCloturees =>
      positions.where((p) => p.estCloturee).toList(growable: false);

  /// Valorisation marchande cumulée des lignes d'actions détenues en FCFA.
  int get valorisationTitres =>
      positionsActives.fold<int>(0, (sum, p) => sum + p.valorisation);

  /// Coût de revient total cumulé des actions détenues en FCFA.
  int get coutRevientTitres =>
      positionsActives.fold<int>(0, (sum, p) => sum + p.coutRevientTotal);

  /// Recherche une position par code de titre (insensible à la casse).
  Position? positionParCode(String codeTitre) {
    final codeMaj = codeTitre.toUpperCase();
    for (final pos in positions) {
      if (pos.codeTitre.toUpperCase() == codeMaj) {
        return pos;
      }
    }
    return null;
  }

  /// Rendement latent global en pourcentage (calculé uniquement pour l'affichage).
  /// Ex: +15.5 pour +15.5%.
  double? get pvLatentePct {
    final cout = coutRevientTitres;
    if (cout <= 0) return null;
    return (pvLatente / cout) * 100.0;
  }

  /// Rendement total cumulé (latente + réalisée) en pourcentage par rapport au coût de revient (affichage).
  double? get pvTotalePct {
    final cout = coutRevientTitres;
    if (cout <= 0) return null;
    return (pvTotale / cout) * 100.0;
  }

  /// Variation journalière globale en pourcentage par rapport à la veille (affichage).
  double? get pvJourPct {
    final valoVeille = valorisationTotale - pvJour;
    if (valoVeille <= 0) return null;
    return (pvJour / valoVeille) * 100.0;
  }

  /// Crée une copie de cette instance avec des champs modifiés.
  Portefeuille copyWith({
    List<Position>? positions,
    int? soldeDisponible,
    int? valorisationTotale,
    int? pvJour,
    int? pvTotale,
    int? pvLatente,
    int? pvRealisee,
    int? fraisTotaux,
  }) {
    return Portefeuille(
      positions: positions ?? this.positions,
      soldeDisponible: soldeDisponible ?? this.soldeDisponible,
      valorisationTotale: valorisationTotale ?? this.valorisationTotale,
      pvJour: pvJour ?? this.pvJour,
      pvTotale: pvTotale ?? this.pvTotale,
      pvLatente: pvLatente ?? this.pvLatente,
      pvRealisee: pvRealisee ?? this.pvRealisee,
      fraisTotaux: fraisTotaux ?? this.fraisTotaux,
    );
  }

  /// Sérialisation en Map clé-valeur.
  Map<String, dynamic> toMap() {
    return {
      'positions': positions.map((p) => p.toMap()).toList(),
      'soldeDisponible': soldeDisponible,
      'valorisationTotale': valorisationTotale,
      'pvJour': pvJour,
      'pvTotale': pvTotale,
      'pvLatente': pvLatente,
      'pvRealisee': pvRealisee,
      'fraisTotaux': fraisTotaux,
    };
  }

  /// Désérialisation depuis une Map clé-valeur.
  factory Portefeuille.fromMap(Map<String, dynamic> map) {
    return Portefeuille(
      positions: (map['positions'] as List<dynamic>)
          .map((item) => Position.fromMap(item as Map<String, dynamic>))
          .toList(),
      soldeDisponible: (map['soldeDisponible'] as num).toInt(),
      valorisationTotale: (map['valorisationTotale'] as num).toInt(),
      pvJour: (map['pvJour'] as num).toInt(),
      pvTotale: (map['pvTotale'] as num).toInt(),
      pvLatente: (map['pvLatente'] as num?)?.toInt() ?? 0,
      pvRealisee: (map['pvRealisee'] as num?)?.toInt() ?? 0,
      fraisTotaux: (map['fraisTotaux'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Portefeuille) return false;
    if (other.soldeDisponible != soldeDisponible ||
        other.valorisationTotale != valorisationTotale ||
        other.pvJour != pvJour ||
        other.pvTotale != pvTotale ||
        other.pvLatente != pvLatente ||
        other.pvRealisee != pvRealisee ||
        other.fraisTotaux != fraisTotaux ||
        other.positions.length != positions.length) {
      return false;
    }
    for (int i = 0; i < positions.length; i++) {
      if (positions[i] != other.positions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(positions),
      soldeDisponible,
      valorisationTotale,
      pvJour,
      pvTotale,
      pvLatente,
      pvRealisee,
      fraisTotaux,
    );
  }

  @override
  String toString() {
    return 'Portefeuille(solde: $soldeDisponible FCFA, valoTotale: $valorisationTotale FCFA, '
        'pvJour: $pvJour FCFA, pvTotale: $pvTotale FCFA, '
        'positionsActives: ${positionsActives.length})';
  }
}
