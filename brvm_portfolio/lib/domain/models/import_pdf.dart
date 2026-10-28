/// Statut de traitement d'un avis d'opéré ou relevé PDF importé.
enum StatutImport {
  /// Le fichier est enregistré et en attente d'analyse OCR / extraction.
  enAttente,

  /// L'analyse et l'extraction des données sont en cours.
  enCours,

  /// L'avis a été extrait avec succès et validé en opération.
  valide,

  /// Le document a été rejeté (format non supporté, données incomplètes).
  rejete,

  /// Le document a déjà été importé antérieurement (empreinte identique).
  doublon,

  /// Une erreur technique est survenue lors de l'extraction ou de la lecture.
  erreur,
}

/// Modèle représentant un avis d'opéré ou relevé de compte au format PDF importé.
class ImportPdf {
  /// Identifiant unique du document importé.
  final String id;

  /// Chemin local ou URI du fichier PDF.
  final String chemin;

  /// Empreinte cryptographique (hash SHA-256) du fichier pour dédoublonnage.
  final String empreinte;

  /// Statut du cycle de vie de l'importation.
  final StatutImport statut;

  /// Données brutes ou structurées extraites du document
  /// (ex: ref_sgi, type_ordre, code_titre, qte, prix, frais_courtage, taxes, net).
  final Map<String, dynamic> champsExtraits;

  /// Date et heure de l'importation du document.
  final DateTime dateImport;

  /// Message explicatif en cas d'erreur ou d'anomalie de détection.
  final String? messageErreur;

  /// Identifiant de l'opération générée dans le journal suite à cet import (si validé).
  final String? operationId;

  /// Nom d'origine du fichier PDF.
  final String? nomFichier;

  const ImportPdf({
    required this.id,
    required this.chemin,
    required this.empreinte,
    required this.statut,
    this.champsExtraits = const {},
    required this.dateImport,
    this.messageErreur,
    this.operationId,
    this.nomFichier,
  });

  /// Indique si l'importation est terminée avec succès.
  bool get estValide => statut == StatutImport.valide;

  /// Indique si l'importation a échoué (erreur ou rejet).
  bool get estEnErreur =>
      statut == StatutImport.erreur || statut == StatutImport.rejete;

  /// Indique s'il s'agit d'un doublon déjà traité.
  bool get estDoublon => statut == StatutImport.doublon;

  /// Crée une copie de cette instance avec des champs modifiés.
  ImportPdf copyWith({
    String? id,
    String? chemin,
    String? empreinte,
    StatutImport? statut,
    Map<String, dynamic>? champsExtraits,
    DateTime? dateImport,
    String? messageErreur,
    String? operationId,
    String? nomFichier,
  }) {
    return ImportPdf(
      id: id ?? this.id,
      chemin: chemin ?? this.chemin,
      empreinte: empreinte ?? this.empreinte,
      statut: statut ?? this.statut,
      champsExtraits: champsExtraits ?? this.champsExtraits,
      dateImport: dateImport ?? this.dateImport,
      messageErreur: messageErreur ?? this.messageErreur,
      operationId: operationId ?? this.operationId,
      nomFichier: nomFichier ?? this.nomFichier,
    );
  }

  /// Sérialisation en Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chemin': chemin,
      'empreinte': empreinte,
      'statut': statut.name,
      'champsExtraits': champsExtraits,
      'dateImport': dateImport.toIso8601String(),
      'messageErreur': messageErreur,
      'operationId': operationId,
      'nomFichier': nomFichier,
    };
  }

  /// Désérialisation depuis une Map.
  factory ImportPdf.fromMap(Map<String, dynamic> map) {
    return ImportPdf(
      id: map['id'] as String,
      chemin: map['chemin'] as String,
      empreinte: map['empreinte'] as String,
      statut: StatutImport.values.byName(map['statut'] as String),
      champsExtraits: (map['champsExtraits'] as Map<String, dynamic>?) ?? const {},
      dateImport: DateTime.parse(map['dateImport'] as String),
      messageErreur: map['messageErreur'] as String?,
      operationId: map['operationId'] as String?,
      nomFichier: map['nomFichier'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImportPdf &&
        other.id == id &&
        other.chemin == chemin &&
        other.empreinte == empreinte &&
        other.statut == statut &&
        other.dateImport == dateImport &&
        other.messageErreur == messageErreur &&
        other.operationId == operationId &&
        other.nomFichier == nomFichier;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chemin,
      empreinte,
      statut,
      dateImport,
      messageErreur,
      operationId,
      nomFichier,
    );
  }

  @override
  String toString() {
    return 'ImportPdf(id: $id, statut: ${statut.name}, empreinte: ${empreinte.substring(0, empreinte.length > 8 ? 8 : empreinte.length)}..., chemin: $chemin)';
  }
}
