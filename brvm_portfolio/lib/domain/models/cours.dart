/// Représente la cotation d'un titre BRVM pour une séance de marché.
/// Tous les montants monétaires sont des entiers FCFA.
class Cours {
  /// Code mnémonique du titre associé (ex: "SNTS", "ECOC").
  final String? codeTitre;

  /// Cours de clôture officiel de la séance en FCFA (entier).
  final int cloture;

  /// Cours d'ouverture de la séance en FCFA (entier, optionnel).
  final int? ouverture;

  /// Cours de clôture de la veille de cotation en FCFA (entier, optionnel).
  final int? coursVeille;

  /// Variation en pourcentage par rapport à la veille (ex: 2.5 pour +2.5%).
  /// Utilisé principalement pour l'affichage.
  final double? variationPct;

  /// Volume de titres échangés durant la séance.
  final int volume;

  /// Source de la donnée de cotation (ex: "BRVM", "SGI", "Manuel").
  final String source;

  /// Date de la séance de cotation.
  final DateTime date;

  const Cours({
    required this.cloture,
    this.codeTitre,
    this.ouverture,
    this.coursVeille,
    this.variationPct,
    this.volume = 0,
    this.source = 'BRVM',
    required this.date,
  });

  /// Cours de la veille de cotation retenu (ou clôture si non renseigné).
  int get coursPrecedent {
    if (coursVeille != null) return coursVeille!;
    if (variationPct != null && (1.0 + variationPct! / 100.0) != 0) {
      return (cloture / (1.0 + variationPct! / 100.0)).round();
    }
    return cloture;
  }

  /// Variation en FCFA par titre par rapport à la veille de cotation.
  int get variationFcfa => cloture - coursPrecedent;

  /// Variation en pourcentage calculée si non fournie explicitement.
  double get variationPourcentageCalculee {
    if (variationPct != null) return variationPct!;
    final precedent = coursPrecedent;
    if (precedent == 0) return 0.0;
    return ((cloture - precedent) / precedent) * 100.0;
  }

  /// Crée une copie de cette instance avec certains champs modifiés.
  Cours copyWith({
    String? codeTitre,
    int? cloture,
    int? ouverture,
    int? coursVeille,
    double? variationPct,
    int? volume,
    String? source,
    DateTime? date,
  }) {
    return Cours(
      codeTitre: codeTitre ?? this.codeTitre,
      cloture: cloture ?? this.cloture,
      ouverture: ouverture ?? this.ouverture,
      coursVeille: coursVeille ?? this.coursVeille,
      variationPct: variationPct ?? this.variationPct,
      volume: volume ?? this.volume,
      source: source ?? this.source,
      date: date ?? this.date,
    );
  }

  /// Sérialisation en Map clé-valeur.
  Map<String, dynamic> toMap() {
    return {
      'codeTitre': codeTitre,
      'cloture': cloture,
      'ouverture': ouverture,
      'coursVeille': coursVeille,
      'variationPct': variationPct,
      'volume': volume,
      'source': source,
      'date': date.toIso8601String(),
    };
  }

  /// Désérialisation depuis une Map clé-valeur.
  factory Cours.fromMap(Map<String, dynamic> map) {
    return Cours(
      codeTitre: map['codeTitre'] as String?,
      cloture: (map['cloture'] as num).toInt(),
      ouverture: (map['ouverture'] as num?)?.toInt(),
      coursVeille: (map['coursVeille'] as num?)?.toInt(),
      variationPct: (map['variationPct'] as num?)?.toDouble(),
      volume: (map['volume'] as num?)?.toInt() ?? 0,
      source: (map['source'] as String?) ?? 'BRVM',
      date: DateTime.parse(map['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cours &&
        other.codeTitre == codeTitre &&
        other.cloture == cloture &&
        other.ouverture == ouverture &&
        other.coursVeille == coursVeille &&
        other.variationPct == variationPct &&
        other.volume == volume &&
        other.source == source &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(
      codeTitre,
      cloture,
      ouverture,
      coursVeille,
      variationPct,
      volume,
      source,
      date,
    );
  }

  @override
  String toString() {
    return 'Cours(code: $codeTitre, cloture: $cloture FCFA, veille: $coursVeille FCFA, '
        'var: $variationPct%, vol: $volume, date: $date)';
  }
}
