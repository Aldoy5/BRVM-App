/// Types d'opérations supportées par le carnet d'ordres
enum OperationType {
  achat,
  vente,
  depot,
  retrait,
}

extension OperationTypeExtensions on OperationType {
  String get label {
    switch (this) {
      case OperationType.achat:
        return 'Achat';
      case OperationType.vente:
        return 'Vente';
      case OperationType.depot:
        return 'Dépôt';
      case OperationType.retrait:
        return 'Retrait';
    }
  }

  bool get isStockOperation =>
      this == OperationType.achat || this == OperationType.vente;

  bool get isCashOperation =>
      this == OperationType.depot || this == OperationType.retrait;
}

/// Modèle représentant une opération d'achat, vente, dépôt ou retrait
class Operation {
  final String id;
  final OperationType type;
  final String? stockCode;
  final String? stockName;
  final int? quantity;
  final int? unitPrice;
  final int fees; // Frais d'intermédiation / SGI
  final double? feeRate; // Taux SGI (%) utilisé lors de l'enregistrement
  final int? cashAmount; // Montant brut pour dépôt / retrait
  final DateTime date;
  final String? notes;

  const Operation({
    required this.id,
    required this.type,
    this.stockCode,
    this.stockName,
    this.quantity,
    this.unitPrice,
    this.fees = 0,
    this.feeRate,
    this.cashAmount,
    required this.date,
    this.notes,
  });

  /// Montant brut hors frais
  int get grossAmount {
    if (type.isStockOperation) {
      return (quantity ?? 0) * (unitPrice ?? 0);
    }
    return cashAmount ?? 0;
  }

  /// Montant net total de l'opération
  int get netAmount {
    switch (type) {
      case OperationType.achat:
        return grossAmount + fees; // Débit total
      case OperationType.vente:
        return grossAmount - fees; // Crédit net
      case OperationType.depot:
        return grossAmount - fees; // Crédit net sur solde
      case OperationType.retrait:
        return grossAmount + fees; // Débit total
    }
  }

  /// Impact sur la trésorerie / solde disponible (positif = crédit, négatif = débit)
  int get cashImpact {
    switch (type) {
      case OperationType.achat:
        return -netAmount;
      case OperationType.vente:
        return netAmount;
      case OperationType.depot:
        return grossAmount - fees;
      case OperationType.retrait:
        return -(grossAmount + fees);
    }
  }

  Operation copyWith({
    String? id,
    OperationType? type,
    String? stockCode,
    String? stockName,
    int? quantity,
    int? unitPrice,
    int? fees,
    double? feeRate,
    int? cashAmount,
    DateTime? date,
    String? notes,
  }) {
    return Operation(
      id: id ?? this.id,
      type: type ?? this.type,
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      fees: fees ?? this.fees,
      feeRate: feeRate ?? this.feeRate,
      cashAmount: cashAmount ?? this.cashAmount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'stockCode': stockCode,
      'stockName': stockName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'fees': fees,
      'feeRate': feeRate,
      'cashAmount': cashAmount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OperationType.achat,
      ),
      stockCode: json['stockCode'] as String?,
      stockName: json['stockName'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      unitPrice: (json['unitPrice'] as num?)?.toInt(),
      fees: (json['fees'] as num?)?.toInt() ?? 0,
      feeRate: (json['feeRate'] as num?)?.toDouble(),
      cashAmount: (json['cashAmount'] as num?)?.toInt(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }
}
