/// Modèle représentant une ligne de position détenue dans le portefeuille.
class Position {
  final String stockCode;
  final String stockName;
  final int quantity;
  final double pru; // Prix de Revient Unitaire (frais inclus)
  final int currentPrice;
  final int previousClosePrice;
  final double dailyVariation;

  const Position({
    required this.stockCode,
    required this.stockName,
    required this.quantity,
    required this.pru,
    required this.currentPrice,
    required this.previousClosePrice,
    required this.dailyVariation,
  });

  /// Valeur actuelle totale de la position en FCFA
  int get totalValuation => quantity * currentPrice;

  /// Montant total investi (frais inclus)
  int get investedAmount => (quantity * pru).round();

  /// Plus-value ou moins-value latente totale en FCFA
  int get totalGainLoss => totalValuation - investedAmount;

  /// Plus-value ou moins-value latente totale en pourcentage
  double get totalGainLossPercent {
    if (investedAmount <= 0) return 0.0;
    return (totalGainLoss / investedAmount) * 100.0;
  }

  /// Variation journalière de la position en FCFA
  int get dailyGainLoss => quantity * (currentPrice - previousClosePrice);

  /// Indique si la position est globalement gagnante
  bool get isGainingTotal => totalGainLoss > 0;

  /// Indique si la position est globalement perdante
  bool get isLosingTotal => totalGainLoss < 0;

  /// Indique si la position est gagnante sur la journée
  bool get isGainingDaily => dailyGainLoss > 0;

  /// Indique si la position est perdante sur la journée
  bool get isLosingDaily => dailyGainLoss < 0;

  Position copyWith({
    String? stockCode,
    String? stockName,
    int? quantity,
    double? pru,
    int? currentPrice,
    int? previousClosePrice,
    double? dailyVariation,
  }) {
    return Position(
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      quantity: quantity ?? this.quantity,
      pru: pru ?? this.pru,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClosePrice: previousClosePrice ?? this.previousClosePrice,
      dailyVariation: dailyVariation ?? this.dailyVariation,
    );
  }
}
