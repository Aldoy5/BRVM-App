/// Types d'opérations enregistrables dans le journal du portefeuille.
enum TypeOperation {
  /// Achat de titres sur le marché BRVM.
  achat,

  /// Vente de titres sur le marché BRVM (partielle ou totale).
  vente,

  /// Dépôt d'espèces sur le compte liquidités de la SGI.
  depot,

  /// Retrait d'espèces depuis le compte liquidités vers un compte bancaire.
  retrait,

  /// Ajustement de solde ou régularisation avec le relevé officiel SGI.
  ajustement,
}

/// Détail des frais appliqués à une opération boursière en FCFA (entiers).
class Frais {
  /// Frais de courtage perçus par la SGI (hors taxes).
  final int courtage;

  /// Commissions de marché (BRVM, DC/BR, CREPMF / AMF-UMOA).
  final int commissions;

  /// Taxes applicables (TVA, taxe sur opérations boursières).
  final int taxes;

  const Frais({
    this.courtage = 0,
    this.commissions = 0,
    this.taxes = 0,
  });

  /// Frais nuls par défaut.
  static const zero = Frais();

  /// Total des frais en FCFA (courtage + commissions + taxes).
  int get total => courtage + commissions + taxes;

  /// Crée une copie de cette instance avec des valeurs modifiées.
  Frais copyWith({
    int? courtage,
    int? commissions,
    int? taxes,
  }) {
    return Frais(
      courtage: courtage ?? this.courtage,
      commissions: commissions ?? this.commissions,
      taxes: taxes ?? this.taxes,
    );
  }

  /// Sérialisation en Map.
  Map<String, dynamic> toMap() {
    return {
      'courtage': courtage,
      'commissions': commissions,
      'taxes': taxes,
    };
  }

  /// Désérialisation depuis une Map.
  factory Frais.fromMap(Map<String, dynamic> map) {
    return Frais(
      courtage: (map['courtage'] as num?)?.toInt() ?? 0,
      commissions: (map['commissions'] as num?)?.toInt() ?? 0,
      taxes: (map['taxes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Frais &&
        other.courtage == courtage &&
        other.commissions == commissions &&
        other.taxes == taxes;
  }

  @override
  int get hashCode => Object.hash(courtage, commissions, taxes);

  @override
  String toString() => 'Frais(courtage: $courtage, commissions: $commissions, taxes: $taxes, total: $total FCFA)';
}

/// Représente une opération unitaire du journal financier.
/// Tous les montants monétaires sont des entiers FCFA.
class Operation {
  /// Identifiant unique de l'opération (UUID ou clé SGI).
  final String id;

  /// Nature de l'opération.
  final TypeOperation type;

  /// Code mnémonique du titre (ex: "SNTS"). Null pour dépôt/retrait/ajustement de trésorerie.
  final String? codeTitre;

  /// Nombre de titres traités (0 pour les opérations de trésorerie pure).
  final int quantite;

  /// Prix d'exécution unitaire en FCFA (0 pour les opérations de trésorerie pure).
  final int prixUnitaire;

  /// Frais ventilés de l'opération en FCFA.
  final Frais frais;

  /// Montant net en FCFA :
  /// - Achat : décaissé = (quantite * prixUnitaire) + frais.total
  /// - Vente : perçu net = (quantite * prixUnitaire) - frais.total
  /// - Dépôt : montant crédité
  /// - Retrait : montant débité
  /// - Ajustement : montant d'ajustement algébrique (+ ou -)
  final int montantNet;

  /// Date d'exécution ou de négociation de l'opération.
  final DateTime date;

  /// Date de valeur comptable ou de règlement / livraison.
  final DateTime? dateValeur;

  /// Référence de l'avis d'opéré ou transaction SGI (ex: "BOD-2026-0042").
  final String? referenceSgi;

  /// Source de l'enregistrement (ex: "manuel", "pdf", "sgi_api").
  final String source;

  /// Commentaire libre ou motif de l'opération.
  final String? commentaire;

  const Operation({
    required this.id,
    required this.type,
    this.codeTitre,
    this.quantite = 0,
    this.prixUnitaire = 0,
    this.frais = Frais.zero,
    required this.montantNet,
    required this.date,
    this.dateValeur,
    this.referenceSgi,
    this.source = 'manuel',
    this.commentaire,
  });

  /// Factory pratique pour un achat de titres.
  factory Operation.achat({
    required String id,
    required String codeTitre,
    required int quantite,
    required int prixUnitaire,
    Frais frais = Frais.zero,
    int? montantNet,
    required DateTime date,
    DateTime? dateValeur,
    String? referenceSgi,
    String source = 'manuel',
    String? commentaire,
  }) {
    final montantCalcule = (quantite * prixUnitaire) + frais.total;
    return Operation(
      id: id,
      type: TypeOperation.achat,
      codeTitre: codeTitre,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      frais: frais,
      montantNet: montantNet ?? montantCalcule,
      date: date,
      dateValeur: dateValeur,
      referenceSgi: referenceSgi,
      source: source,
      commentaire: commentaire,
    );
  }

  /// Factory pratique pour une vente de titres.
  factory Operation.vente({
    required String id,
    required String codeTitre,
    required int quantite,
    required int prixUnitaire,
    Frais frais = Frais.zero,
    int? montantNet,
    required DateTime date,
    DateTime? dateValeur,
    String? referenceSgi,
    String source = 'manuel',
    String? commentaire,
  }) {
    final montantCalcule = (quantite * prixUnitaire) - frais.total;
    return Operation(
      id: id,
      type: TypeOperation.vente,
      codeTitre: codeTitre,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      frais: frais,
      montantNet: montantNet ?? montantCalcule,
      date: date,
      dateValeur: dateValeur,
      referenceSgi: referenceSgi,
      source: source,
      commentaire: commentaire,
    );
  }

  /// Factory pratique pour un dépôt d'espèces.
  factory Operation.depot({
    required String id,
    required int montant,
    Frais frais = Frais.zero,
    int? montantNet,
    required DateTime date,
    DateTime? dateValeur,
    String? referenceSgi,
    String source = 'manuel',
    String? commentaire,
  }) {
    return Operation(
      id: id,
      type: TypeOperation.depot,
      codeTitre: null,
      quantite: 0,
      prixUnitaire: 0,
      frais: frais,
      montantNet: montantNet ?? (montant - frais.total),
      date: date,
      dateValeur: dateValeur,
      referenceSgi: referenceSgi,
      source: source,
      commentaire: commentaire,
    );
  }

  /// Factory pratique pour un retrait d'espèces.
  factory Operation.retrait({
    required String id,
    required int montant,
    Frais frais = Frais.zero,
    int? montantNet,
    required DateTime date,
    DateTime? dateValeur,
    String? referenceSgi,
    String source = 'manuel',
    String? commentaire,
  }) {
    return Operation(
      id: id,
      type: TypeOperation.retrait,
      codeTitre: null,
      quantite: 0,
      prixUnitaire: 0,
      frais: frais,
      montantNet: montantNet ?? (montant + frais.total),
      date: date,
      dateValeur: dateValeur,
      referenceSgi: referenceSgi,
      source: source,
      commentaire: commentaire,
    );
  }

  /// Factory pratique pour un ajustement de solde (positif ou négatif).
  factory Operation.ajustement({
    required String id,
    required int montant,
    required DateTime date,
    String? codeTitre,
    DateTime? dateValeur,
    String? referenceSgi,
    String source = 'manuel',
    String? commentaire,
  }) {
    return Operation(
      id: id,
      type: TypeOperation.ajustement,
      codeTitre: codeTitre,
      quantite: 0,
      prixUnitaire: 0,
      frais: Frais.zero,
      montantNet: montant,
      date: date,
      dateValeur: dateValeur,
      referenceSgi: referenceSgi,
      source: source,
      commentaire: commentaire,
    );
  }

  /// Montant brut de négociation (quantité * prixUnitaire).
  int get montantBrut => quantite * prixUnitaire;

  /// Crée une copie de cette instance avec des champs modifiés.
  Operation copyWith({
    String? id,
    TypeOperation? type,
    String? codeTitre,
    int? quantite,
    int? prixUnitaire,
    Frais? frais,
    int? montantNet,
    DateTime? date,
    DateTime? dateValeur,
    String? referenceSgi,
    String? source,
    String? commentaire,
  }) {
    return Operation(
      id: id ?? this.id,
      type: type ?? this.type,
      codeTitre: codeTitre ?? this.codeTitre,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      frais: frais ?? this.frais,
      montantNet: montantNet ?? this.montantNet,
      date: date ?? this.date,
      dateValeur: dateValeur ?? this.dateValeur,
      referenceSgi: referenceSgi ?? this.referenceSgi,
      source: source ?? this.source,
      commentaire: commentaire ?? this.commentaire,
    );
  }

  /// Sérialisation en Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'codeTitre': codeTitre,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'frais': frais.toMap(),
      'montantNet': montantNet,
      'date': date.toIso8601String(),
      'dateValeur': dateValeur?.toIso8601String(),
      'referenceSgi': referenceSgi,
      'source': source,
      'commentaire': commentaire,
    };
  }

  /// Désérialisation depuis une Map.
  factory Operation.fromMap(Map<String, dynamic> map) {
    return Operation(
      id: map['id'] as String,
      type: TypeOperation.values.byName(map['type'] as String),
      codeTitre: map['codeTitre'] as String?,
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toInt() ?? 0,
      frais: map['frais'] != null
          ? Frais.fromMap(map['frais'] as Map<String, dynamic>)
          : Frais.zero,
      montantNet: (map['montantNet'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      dateValeur: map['dateValeur'] != null
          ? DateTime.parse(map['dateValeur'] as String)
          : null,
      referenceSgi: map['referenceSgi'] as String?,
      source: (map['source'] as String?) ?? 'manuel',
      commentaire: map['commentaire'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Operation &&
        other.id == id &&
        other.type == type &&
        other.codeTitre == codeTitre &&
        other.quantite == quantite &&
        other.prixUnitaire == prixUnitaire &&
        other.frais == frais &&
        other.montantNet == montantNet &&
        other.date == date &&
        other.dateValeur == dateValeur &&
        other.referenceSgi == referenceSgi &&
        other.source == source &&
        other.commentaire == commentaire;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      codeTitre,
      quantite,
      prixUnitaire,
      frais,
      montantNet,
      date,
      dateValeur,
      referenceSgi,
      source,
      commentaire,
    );
  }

  @override
  String toString() {
    return 'Operation(id: $id, type: ${type.name}, titre: $codeTitre, '
        'qte: $quantite, pu: $prixUnitaire FCFA, frais: ${frais.total} FCFA, '
        'net: $montantNet FCFA, date: $date)';
  }
}
