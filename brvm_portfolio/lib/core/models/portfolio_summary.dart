/// Résumé global de l'état du portefeuille d'investissement.
class PortfolioSummary {
  final int totalValuation; // Valeur totale des titres en portefeuille
  final int cashBalance; // Solde espèces disponible sur le compte SGI
  final int dailyGainLoss; // Variation du jour en FCFA
  final double dailyGainLossPercent; // Variation du jour en %
  final int totalGainLoss; // Plus-value / Moins-value latente totale en FCFA
  final double totalGainLossPercent; // Plus-value latente totale en %
  final DateTime marketDate; // Date du dernier cours relevé
  final int positionsCount; // Nombre de lignes actives

  const PortfolioSummary({
    required this.totalValuation,
    required this.cashBalance,
    required this.dailyGainLoss,
    required this.dailyGainLossPercent,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.marketDate,
    required this.positionsCount,
  });

  /// Patrimoine total = Valeur des titres + Liquidités
  int get totalWealth => totalValuation + cashBalance;

  /// Indique si la journée est en gain
  bool get isGainingDaily => dailyGainLoss > 0;

  /// Indique si la journée est en perte
  bool get isLosingDaily => dailyGainLoss < 0;

  /// Indique si la performance globale est en gain
  bool get isGainingTotal => totalGainLoss > 0;

  /// Indique si la performance globale est en perte
  bool get isLosingTotal => totalGainLoss < 0;
}
