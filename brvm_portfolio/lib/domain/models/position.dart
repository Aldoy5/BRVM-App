/// Représente une position calculée pour un titre donné dans le portefeuille.
/// Tous les montants monétaires sont des entiers FCFA.
class Position {
  /// Code mnémonique du titre (ex: "SNTS").
  final String codeTitre;

  /// Quantité actuelle de titres en portefeuille (>= 0).
  final int quantite;

  /// Prix de Revient Unitaire pondéré en FCFA (frais inclus).
  final int pru;

  /// Dernier cours de clôture connu en FCFA.
  final int dernierCours;

  /// Cours de clôture de la séance précédente en FCFA.
  final int? coursVeille;

  /// Valorisation brute actuelle de la ligne en FCFA : quantite × dernierCours.
  final int valorisation;

  /// Plus-value ou moins-value latente en FCFA : valorisation - (quantite × pru).
  final int pvLatente;

  /// Variation de valeur sur la séance du jour en FCFA :
  /// quantite × (dernierCours - coursVeille).
  final int variationJour;

  /// Plus-value ou moins-value cumulée réalisée lors des ventes antérieures en FCFA.
  final int pvRealisee;

  /// Total des frais engagés (achats et ventes) sur ce titre en FCFA.
  final int fraisCumules;

  /// Nombre cumulé de titres achetés historiquement.
  final int quantiteAchetee;

  /// Nombre cumulé de titres vendus historiquement.
  final int quantiteVendue;

  const Position({
    required this.codeTitre,
    required this.quantite,
    required this.pru,
    required this.dernierCours,
    this.coursVeille,
    required this.valorisation,
    required this.pvLatente,
    required this.variationJour,
    this.pvRealisee = 0,
    this.fraisCumules = 0,
    this.quantiteAchetee = 0,
    this.quantiteVendue = 0,
  });

  /// Factory construisant une position en calculant automatiquement la valorisation,
  /// la plus-value latente et la variation du jour.
  factory Position.calculer({
    required String codeTitre,
    required int quantite,
    required int pru,
    required int dernierCours,
    int? coursVeille,
    int pvRealisee = 0,
    int fraisCumules = 0,
    int quantiteAchetee = 0,
    int quantiteVendue = 0,
  }) {
    final valorisation = quantite * dernierCours;
    final coutRevient = quantite * pru;
    final pvLatente = valorisation - coutRevient;
    final referenceVeille = coursVeille ?? dernierCours;
    final variationJour = quantite * (dernierCours - referenceVeille);

    return Position(
      codeTitre: codeTitre,
      quantite: quantite,
      pru: pru,
      dernierCours: dernierCours,
      coursVeille: coursVeille,
      valorisation: valorisation,
      pvLatente: pvLatente,
      variationJour: variationJour,
      pvRealisee: pvRealisee,
      fraisCumules: fraisCumules,
      quantiteAchetee: quantiteAchetee,
      quantiteVendue: quantiteVendue,
    );
  }

  /// Indique si la ligne est totalement soldée (quantité = 0).
  bool get estCloturee => quantite == 0;

  /// Indique si la ligne est actuellement active (quantité > 0).
  bool get estActive => quantite > 0;

  /// Coût de revient total de la position résiduelle en FCFA (quantite × pru).
  int get coutRevientTotal => quantite * pru;

  /// Plus-value totale sur ce titre (latente actuelle + réalisée passée).
  int get pvTotale => pvLatente + pvRealisee;

  /// Plus-value latente en pourcentage (calculée uniquement pour l'affichage).
  /// Renvoie null si la quantité ou le PRU est nul.
  double? get pvLatentePct {
    if (quantite <= 0 || pru <= 0) return null;
    return ((dernierCours - pru) / pru) * 100.0;
  }

  /// Variation du jour en pourcentage (calculée uniquement pour l'affichage).
  /// Renvoie null si le cours de la veille n'est pas renseigné ou nul.
  double? get variationJourPct {
    final reference = coursVeille;
    if (reference == null || reference <= 0) return null;
    return ((dernierCours - reference) / reference) * 100.0;
  }

  /// Crée une copie de cette instance avec certains champs modifiés.
  Position copyWith({
    String? codeTitre,
    int? quantite,
    int? pru,
    int? dernierCours,
    int? coursVeille,
    int? valorisation,
    int? pvLatente,
    int? variationJour,
    int? pvRealisee,
    int? fraisCumules,
    int? quantiteAchetee,
    int? quantiteVendue,
  }) {
    return Position(
      codeTitre: codeTitre ?? this.codeTitre,
      quantite: quantite ?? this.quantite,
      pru: pru ?? this.pru,
      dernierCours: dernierCours ?? this.dernierCours,
      coursVeille: coursVeille ?? this.coursVeille,
      valorisation: valorisation ?? this.valorisation,
      pvLatente: pvLatente ?? this.pvLatente,
      variationJour: variationJour ?? this.variationJour,
      pvRealisee: pvRealisee ?? this.pvRealisee,
      fraisCumules: fraisCumules ?? this.fraisCumules,
      quantiteAchetee: quantiteAchetee ?? this.quantiteAchetee,
      quantiteVendue: quantiteVendue ?? this.quantiteVendue,
    );
  }

  /// Sérialisation en Map clé-valeur.
  Map<String, dynamic> toMap() {
    return {
      'codeTitre': codeTitre,
      'quantite': quantite,
      'pru': pru,
      'dernierCours': dernierCours,
      'coursVeille': coursVeille,
      'valorisation': valorisation,
      'pvLatente': pvLatente,
      'variationJour': variationJour,
      'pvRealisee': pvRealisee,
      'fraisCumules': fraisCumules,
      'quantiteAchetee': quantiteAchetee,
      'quantiteVendue': quantiteVendue,
    };
  }

  /// Désérialisation depuis une Map clé-valeur.
  factory Position.fromMap(Map<String, dynamic> map) {
    return Position(
      codeTitre: map['codeTitre'] as String,
      quantite: (map['quantite'] as num).toInt(),
      pru: (map['pru'] as num).toInt(),
      dernierCours: (map['dernierCours'] as num).toInt(),
      coursVeille: (map['coursVeille'] as num?)?.toInt(),
      valorisation: (map['valorisation'] as num).toInt(),
      pvLatente: (map['pvLatente'] as num).toInt(),
      variationJour: (map['variationJour'] as num).toInt(),
      pvRealisee: (map['pvRealisee'] as num?)?.toInt() ?? 0,
      fraisCumules: (map['fraisCumules'] as num?)?.toInt() ?? 0,
      quantiteAchetee: (map['quantiteAchetee'] as num?)?.toInt() ?? 0,
      quantiteVendue: (map['quantiteVendue'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position &&
        other.codeTitre == codeTitre &&
        other.quantite == quantite &&
        other.pru == pru &&
        other.dernierCours == dernierCours &&
        other.coursVeille == coursVeille &&
        other.valorisation == valorisation &&
        other.pvLatente == pvLatente &&
        other.variationJour == variationJour &&
        other.pvRealisee == pvRealisee &&
        other.fraisCumules == fraisCumules &&
        other.quantiteAchetee == quantiteAchetee &&
        other.quantiteVendue == quantiteVendue;
  }

  @override
  int get hashCode {
    return Object.hash(
      codeTitre,
      quantite,
      pru,
      dernierCours,
      coursVeille,
      valorisation,
      pvLatente,
      variationJour,
      pvRealisee,
      fraisCumules,
      quantiteAchetee,
      quantiteVendue,
    );
  }

  @override
  String toString() {
    return 'Position($codeTitre: $quantite titres, PRU: $pru FCFA, '
        'cours: $dernierCours FCFA, valo: $valorisation FCFA, '
        'pvLatente: $pvLatente FCFA, varJour: $variationJour FCFA, '
        'pvRealisee: $pvRealisee FCFA)';
  }
}
