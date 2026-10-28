/// Modèle représentant un titre coté à la BRVM (Bourse Régionale des Valeurs Mobilières).
class Titre {
  /// Code mnémonique ou symbole officiel BRVM (ex: "SNTS", "ECOC", "SGBC").
  final String code;

  /// Raison sociale ou nom de l'émetteur (ex: "Sonatel", "Ecobank CI").
  final String nom;

  /// Secteur d'activité officiel BRVM (ex: "Services Publics", "Finances", "Industrie", "Distribution").
  final String secteur;

  /// Pays d'origine de l'émetteur dans la zone UEMOA (ex: "Sénégal", "Côte d'Ivoire", "Togo").
  final String pays;

  /// Indique si le titre est activement coté et négociable sur le marché.
  final bool actif;

  const Titre({
    required this.code,
    required this.nom,
    required this.secteur,
    required this.pays,
    this.actif = true,
  });

  /// Crée une copie de cette instance avec certains champs modifiés.
  Titre copyWith({
    String? code,
    String? nom,
    String? secteur,
    String? pays,
    bool? actif,
  }) {
    return Titre(
      code: code ?? this.code,
      nom: nom ?? this.nom,
      secteur: secteur ?? this.secteur,
      pays: pays ?? this.pays,
      actif: actif ?? this.actif,
    );
  }

  /// Sérialisation en Map clé-valeur.
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nom': nom,
      'secteur': secteur,
      'pays': pays,
      'actif': actif,
    };
  }

  /// Désérialisation depuis une Map clé-valeur.
  factory Titre.fromMap(Map<String, dynamic> map) {
    return Titre(
      code: map['code'] as String,
      nom: map['nom'] as String,
      secteur: map['secteur'] as String,
      pays: map['pays'] as String,
      actif: (map['actif'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Titre &&
        other.code == code &&
        other.nom == nom &&
        other.secteur == secteur &&
        other.pays == pays &&
        other.actif == actif;
  }

  @override
  int get hashCode {
    return Object.hash(code, nom, secteur, pays, actif);
  }

  @override
  String toString() {
    return 'Titre(code: $code, nom: $nom, secteur: $secteur, pays: $pays, actif: $actif)';
  }
}
