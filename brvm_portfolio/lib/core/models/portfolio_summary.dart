/// Performance financière du portefeuille sur une séance de marché journalière.
class DailySessionPerformance {
  final DateTime date;
  final String dateLabel; // ex: "Aujourd'hui", "Hier (Veille)", "04 nov."
  final int valuation; // Valorisation totale des titres à cette clôture
  final int gainLoss; // Gain/Perte réalisé sur la séance en FCFA
  final double variationPercent; // Variation de la séance en %

  const DailySessionPerformance({
    required this.date,
    required this.dateLabel,
    required this.valuation,
    required this.gainLoss,
    required this.variationPercent,
  });

  /// Indique si la séance a été en gain
  bool get isGaining => gainLoss > 0;

  /// Indique si la séance a été en perte
  bool get isLosing => gainLoss < 0;

  /// Indique si la séance a été neutre (0 FCFA)
  bool get isNeutral => gainLoss == 0;
}

/// Résumé global de l'état du portefeuille d'investissement.
class PortfolioSummary {
  final int totalValuation; // Valeur totale actuelle des titres en portefeuille
  final int cashBalance; // Solde espèces disponible sur le compte SGI
  final int dailyGainLoss; // Variation du jour en FCFA (Aujourd'hui vs Veille)
  final double dailyGainLossPercent; // Variation du jour en %
  final int yesterdayGainLoss; // Gain ou perte réalisé la veille en FCFA (Veille vs Avant-veille)
  final double yesterdayGainLossPercent; // Variation de la veille en %
  final int yesterdayValuation; // Valorisation des titres à la clôture de la veille
  final int totalGainLoss; // Plus-value / Moins-value latente totale en FCFA
  final double totalGainLossPercent; // Plus-value latente totale en %
  final DateTime marketDate; // Date du dernier cours relevé
  final int positionsCount; // Nombre de lignes actives
  final List<DailySessionPerformance> sessionHistory; // Historique jour par jour des séances

  const PortfolioSummary({
    required this.totalValuation,
    required this.cashBalance,
    required this.dailyGainLoss,
    required this.dailyGainLossPercent,
    this.yesterdayGainLoss = 0,
    this.yesterdayGainLossPercent = 0.0,
    this.yesterdayValuation = 0,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.marketDate,
    required this.positionsCount,
    this.sessionHistory = const [],
  });

  /// Patrimoine total = Valeur des titres + Liquidités
  int get totalWealth => totalValuation + cashBalance;

  /// Indique si la journée est en gain
  bool get isGainingDaily => dailyGainLoss > 0;

  /// Indique si la journée est en perte
  bool get isLosingDaily => dailyGainLoss < 0;

  /// Indique si la séance de la veille a été en gain
  bool get isGainingYesterday => yesterdayGainLoss > 0;

  /// Indique si la séance de la veille a été en perte
  bool get isLosingYesterday => yesterdayGainLoss < 0;

  /// Indique si la performance globale est en gain
  bool get isGainingTotal => totalGainLoss > 0;

  /// Indique si la performance globale est en perte
  bool get isLosingTotal => totalGainLoss < 0;
}
