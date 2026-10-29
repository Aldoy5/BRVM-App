/// Sens de l'ordre boursier.
enum Sens { achat, vente }

/// Type de cours spécifié dans l'ordre.
enum TypeCours { limite, autre }

/// Type de document PDF reconnu.
enum TypeDocument { ordreAchat, ordreVente, avisOpere, inconnu }

/// Gravité d'une alerte d'extraction ou de validation.
enum Severite { bloquant, alerte, info }

/// Alerte émise lors de l'extraction ou de la validation d'un ordre.
class Alerte {
  final String code;
  final Severite severite;
  final String message;

  const Alerte({
    required this.code,
    required this.severite,
    required this.message,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alerte &&
        other.code == code &&
        other.severite == severite &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(code, severite, message);

  @override
  String toString() => 'Alerte($code, ${severite.name}: $message)';
}

/// Résultat de l'extraction d'un ordre d'achat ou de vente depuis un PDF.
/// Le parseur ne lève jamais d'exception : il renvoie ce qu'il a compris et des alertes.
class ParsedOrder {
  final String sgi; // ex: 'BICI BOURSE'
  final String sgiSlug; // ex: 'bici_bourse'
  final String? numeroOrdre; // ex: '35968'
  final Sens? sens; // achat | vente
  final int? quantite;
  final String? codeTitre; // ex: 'SIBC'
  final String? isin; // ex: 'CI0000001871'
  final String? libelle; // ex: 'SIBC'
  final TypeCours typeCours; // limite | autre
  final int? prixLimite; // en FCFA entier
  final DateTime? dateValidite;
  final DateTime? recuLe; // date + heure de réception
  final List<Alerte> alertes;

  const ParsedOrder({
    required this.sgi,
    required this.sgiSlug,
    this.numeroOrdre,
    this.sens,
    this.quantite,
    this.codeTitre,
    this.isin,
    this.libelle,
    this.typeCours = TypeCours.autre,
    this.prixLimite,
    this.dateValidite,
    this.recuLe,
    this.alertes = const [],
  });

  ParsedOrder copyWith({
    String? sgi,
    String? sgiSlug,
    String? numeroOrdre,
    Sens? sens,
    int? quantite,
    String? codeTitre,
    String? isin,
    String? libelle,
    TypeCours? typeCours,
    int? prixLimite,
    DateTime? dateValidite,
    DateTime? recuLe,
    List<Alerte>? alertes,
  }) {
    return ParsedOrder(
      sgi: sgi ?? this.sgi,
      sgiSlug: sgiSlug ?? this.sgiSlug,
      numeroOrdre: numeroOrdre ?? this.numeroOrdre,
      sens: sens ?? this.sens,
      quantite: quantite ?? this.quantite,
      codeTitre: codeTitre ?? this.codeTitre,
      isin: isin ?? this.isin,
      libelle: libelle ?? this.libelle,
      typeCours: typeCours ?? this.typeCours,
      prixLimite: prixLimite ?? this.prixLimite,
      dateValidite: dateValidite ?? this.dateValidite,
      recuLe: recuLe ?? this.recuLe,
      alertes: alertes ?? this.alertes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ParsedOrder) return false;
    if (other.sgi != sgi ||
        other.sgiSlug != sgiSlug ||
        other.numeroOrdre != numeroOrdre ||
        other.sens != sens ||
        other.quantite != quantite ||
        other.codeTitre != codeTitre ||
        other.isin != isin ||
        other.libelle != libelle ||
        other.typeCours != typeCours ||
        other.prixLimite != prixLimite ||
        other.dateValidite != dateValidite ||
        other.recuLe != recuLe ||
        other.alertes.length != alertes.length) {
      return false;
    }
    for (int i = 0; i < alertes.length; i++) {
      if (alertes[i] != other.alertes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      sgi,
      sgiSlug,
      numeroOrdre,
      sens,
      quantite,
      codeTitre,
      isin,
      libelle,
      typeCours,
      prixLimite,
      dateValidite,
      recuLe,
      Object.hashAll(alertes),
    );
  }

  @override
  String toString() {
    return 'ParsedOrder(sgi: $sgi, n°: $numeroOrdre, sens: ${sens?.name}, '
        'titre: $codeTitre, qte: $quantite, limite: $prixLimite FCFA, alertes: ${alertes.length})';
  }
}
