/// Modèle représentant une ligne de position détenue dans le portefeuille.
class Position {
  final String stockCode;
  final String stockName;
  final int quantity;
  final double pru; // Prix de Revient Unitaire (frais inclus)
  final int currentPrice;
  final int previousClosePrice;
  final int dayBeforeYesterdayPrice; // Cours de clôture de l'avant-veille (J-2)
  final double dailyVariation;
  final List<double> historicalPrices; // Historique des cours récents

  const Position({
    required this.stockCode,
    required this.stockName,
    required this.quantity,
    required this.pru,
    required this.currentPrice,
    required this.previousClosePrice,
    this.dayBeforeYesterdayPrice = 0,
    required this.dailyVariation,
    this.historicalPrices = const [],
  });

  /// Cours effectif de l'avant-veille (fallback sur previousClosePrice si non renseigné)
  int get effectiveDayBeforeYesterdayPrice =>
      dayBeforeYesterdayPrice > 0 ? dayBeforeYesterdayPrice : previousClosePrice;

  /// Valeur actuelle totale de la position en FCFA
  int get totalValuation => quantity * currentPrice;

  /// Valeur de la position à la clôture de la veille en FCFA
  int get yesterdayValuation => quantity * previousClosePrice;

  /// Montant total investi (frais inclus)
  int get investedAmount => (quantity * pru).round();

  /// Plus-value ou moins-value latente totale en FCFA
  int get totalGainLoss => totalValuation - investedAmount;

  /// Plus-value ou moins-value latente totale en pourcentage
  double get totalGainLossPercent {
    if (investedAmount <= 0) return 0.0;
    return (totalGainLoss / investedAmount) * 100.0;
  }

  /// Variation journalière de la position en FCFA (Aujourd'hui vs Veille)
  int get dailyGainLoss => quantity * (currentPrice - previousClosePrice);

  /// Gain ou perte réalisé la veille en FCFA (Veille vs Avant-veille)
  int get yesterdayGainLoss =>
      quantity * (previousClosePrice - effectiveDayBeforeYesterdayPrice);

  /// Variation en % réalisée la veille
  double get yesterdayVariation {
    final base = effectiveDayBeforeYesterdayPrice;
    if (base <= 0) return 0.0;
    return ((previousClosePrice - base) / base) * 100.0;
  }

  /// Indique si la position est globalement gagnante
  bool get isGainingTotal => totalGainLoss > 0;

  /// Indique si la position est globalement perdante
  bool get isLosingTotal => totalGainLoss < 0;

  /// Indique si la position est gagnante sur la journée en cours
  bool get isGainingDaily => dailyGainLoss > 0;

  /// Indique si la position est perdante sur la journée en cours
  bool get isLosingDaily => dailyGainLoss < 0;

  /// Indique si la position a été gagnante la veille
  bool get isGainingYesterday => yesterdayGainLoss > 0;

  /// Indique si la position a été perdante la veille
  bool get isLosingYesterday => yesterdayGainLoss < 0;

  Position copyWith({
    String? stockCode,
    String? stockName,
    int? quantity,
    double? pru,
    int? currentPrice,
    int? previousClosePrice,
    int? dayBeforeYesterdayPrice,
    double? dailyVariation,
    List<double>? historicalPrices,
  }) {
    return Position(
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      quantity: quantity ?? this.quantity,
      pru: pru ?? this.pru,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClosePrice: previousClosePrice ?? this.previousClosePrice,
      dayBeforeYesterdayPrice:
          dayBeforeYesterdayPrice ?? this.dayBeforeYesterdayPrice,
      dailyVariation: dailyVariation ?? this.dailyVariation,
      historicalPrices: historicalPrices ?? this.historicalPrices,
    );
  }
}
