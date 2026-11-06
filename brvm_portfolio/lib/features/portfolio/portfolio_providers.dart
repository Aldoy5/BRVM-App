import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/operation.dart';
import '../../core/models/position.dart';
import '../../core/models/portfolio_summary.dart';
import '../history/history_providers.dart';
import '../market/market_providers.dart';

/// Provider calculant la liste des positions ouvertes détenues en portefeuille
/// à partir des opérations enregistrées et des cours actuels du marché.
final portfolioPositionsProvider = Provider<List<Position>>((ref) {
  final operations = ref.watch(operationsProvider);
  final stocks = ref.watch(marketStocksProvider);

  // Map des titres par code pour un accès O(1)
  final stockMap = {for (final s in stocks) s.code.toUpperCase(): s};

  // Traitement séquentiel chronologique pour calculer le PRU (Prix Moyen Pondéré)
  final sortedOps = [...operations]..sort((a, b) => a.date.compareTo(b.date));

  final Map<String, int> quantities = {};
  final Map<String, double> prus = {};

  for (final op in sortedOps) {
    if (!op.type.isStockOperation || op.stockCode == null) continue;
    final code = op.stockCode!.toUpperCase();
    final qty = op.quantity ?? 0;
    final price = op.unitPrice ?? 0;
    final fees = op.fees;

    if (op.type == OperationType.achat) {
      final currentQty = quantities[code] ?? 0;
      final currentPru = prus[code] ?? 0.0;
      final newTotalCost = (currentQty * currentPru) + (qty * price + fees);
      final newQty = currentQty + qty;

      quantities[code] = newQty;
      prus[code] = newQty > 0 ? (newTotalCost / newQty) : 0.0;
    } else if (op.type == OperationType.vente) {
      final currentQty = quantities[code] ?? 0;
      final newQty = currentQty - qty;
      quantities[code] = newQty > 0 ? newQty : 0;
      // Le PRU reste inchangé lors d'une cession en comptabilité PMP
    }
  }

  // Construction des objets Position pour les lignes actives (quantité > 0)
  final List<Position> positions = [];
  quantities.forEach((code, qty) {
    if (qty > 0) {
      final stock = stockMap[code];
      final stockName = stock?.name ?? code;
      final currentPrice = stock?.currentPrice ?? 0;
      final prevPrice = stock?.previousClosePrice ?? currentPrice;
      final dailyVariation = stock?.dailyVariation ?? 0.0;
      final pru = prus[code] ?? currentPrice.toDouble();

      // Extraction du cours de l'avant-veille (J-2) depuis l'historique des cotations
      final hist = stock?.historicalPrices ?? const [];
      int dayBeforeYesterday = prevPrice;
      if (hist.length >= 3) {
        dayBeforeYesterday = hist[hist.length - 3].round();
      } else if (hist.length == 2 && hist.last.round() == currentPrice) {
        dayBeforeYesterday = hist.first.round();
      }

      positions.add(
        Position(
          stockCode: code,
          stockName: stockName,
          quantity: qty,
          pru: pru,
          currentPrice: currentPrice,
          previousClosePrice: prevPrice,
          dayBeforeYesterdayPrice: dayBeforeYesterday,
          dailyVariation: dailyVariation,
          historicalPrices: hist,
        ),
      );
    }
  });

  // Tri par valorisation décroissante (les plus grosses lignes en haut)
  positions.sort((a, b) => b.totalValuation.compareTo(a.totalValuation));

  return positions;
});

/// Provider pour vérifier si une action donnée est détenue en portefeuille
final positionByStockCodeProvider = Provider.family<Position?, String>((ref, code) {
  final positions = ref.watch(portfolioPositionsProvider);
  final upperCode = code.toUpperCase();
  for (final p in positions) {
    if (p.stockCode.toUpperCase() == upperCode) return p;
  }
  return null;
});

/// Provider du solde espèces disponible calculé depuis les flux de trésorerie
final cashBalanceProvider = Provider<int>((ref) {
  final operations = ref.watch(operationsProvider);
  int balance = 0;
  for (final op in operations) {
    balance += op.cashImpact;
  }
  return balance;
});

/// Provider de synthèse globale du portefeuille (Hero card)
final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final positions = ref.watch(portfolioPositionsProvider);
  final cashBalance = ref.watch(cashBalanceProvider);
  final marketDate = ref.watch(lastMarketUpdateTimeProvider);

  int totalValuation = 0;
  int totalInvested = 0;
  int dailyGainLoss = 0;
  int yesterdayValuation = 0;
  int yesterdayGainLoss = 0;

  for (final pos in positions) {
    totalValuation += pos.totalValuation;
    totalInvested += pos.investedAmount;
    dailyGainLoss += pos.dailyGainLoss;
    yesterdayValuation += pos.yesterdayValuation;
    yesterdayGainLoss += pos.yesterdayGainLoss;
  }

  // Performance globale
  final totalGainLoss = totalValuation - totalInvested;
  final totalGainLossPercent = totalInvested > 0
      ? (totalGainLoss / totalInvested) * 100.0
      : 0.0;

  // Performance Aujourd'hui vs Veille
  final previousDayValuation = totalValuation - dailyGainLoss;
  final dailyGainLossPercent = previousDayValuation > 0
      ? (dailyGainLoss / previousDayValuation) * 100.0
      : 0.0;

  // Performance Veille vs Avant-veille
  final dayBeforeYesterdayValuation = yesterdayValuation - yesterdayGainLoss;
  final yesterdayGainLossPercent = dayBeforeYesterdayValuation > 0
      ? (yesterdayGainLoss / dayBeforeYesterdayValuation) * 100.0
      : 0.0;

  // Construction de l'historique jour par jour des dernières séances (Cas 3)
  final List<DailySessionPerformance> history = [];

  // Séance 1 : Aujourd'hui (séance en cours)
  history.add(
    DailySessionPerformance(
      date: marketDate,
      dateLabel: "Aujourd'hui (${DateFormat('dd MMM', 'fr_FR').format(marketDate)})",
      valuation: totalValuation,
      gainLoss: dailyGainLoss,
      variationPercent: dailyGainLossPercent,
    ),
  );

  // Séance 2 : Hier (clôture de la veille)
  final yesterdayDate = marketDate.subtract(const Duration(days: 1));
  history.add(
    DailySessionPerformance(
      date: yesterdayDate,
      dateLabel: "Hier (${DateFormat('dd MMM', 'fr_FR').format(yesterdayDate)})",
      valuation: yesterdayValuation,
      gainLoss: yesterdayGainLoss,
      variationPercent: yesterdayGainLossPercent,
    ),
  );

  // Séances antérieures reconstituées depuis historicalPrices (jusqu'à 3 séances de plus)
  for (int step = 2; step <= 4; step++) {
    int pastValuation = 0;
    int pastPriorValuation = 0;
    bool hasData = false;

    for (final pos in positions) {
      final hist = pos.historicalPrices;
      final targetIdx = hist.length - 1 - step;
      final priorIdx = targetIdx - 1;

      if (targetIdx >= 0 && targetIdx < hist.length) {
        final p = hist[targetIdx].round();
        pastValuation += pos.quantity * p;
        hasData = true;

        if (priorIdx >= 0 && priorIdx < hist.length) {
          pastPriorValuation += pos.quantity * hist[priorIdx].round();
        } else {
          pastPriorValuation += pos.quantity * p;
        }
      } else {
        pastValuation += pos.yesterdayValuation;
        pastPriorValuation += pos.yesterdayValuation;
      }
    }

    if (hasData && pastPriorValuation > 0) {
      final pastGain = pastValuation - pastPriorValuation;
      final pastVariation = (pastGain / pastPriorValuation) * 100.0;
      final pastDate = marketDate.subtract(Duration(days: step));

      history.add(
        DailySessionPerformance(
          date: pastDate,
          dateLabel: DateFormat('d MMMM yyyy', 'fr_FR').format(pastDate),
          valuation: pastValuation,
          gainLoss: pastGain,
          variationPercent: pastVariation,
        ),
      );
    }
  }

  return PortfolioSummary(
    totalValuation: totalValuation,
    cashBalance: cashBalance,
    dailyGainLoss: dailyGainLoss,
    dailyGainLossPercent: dailyGainLossPercent,
    yesterdayValuation: yesterdayValuation,
    yesterdayGainLoss: yesterdayGainLoss,
    yesterdayGainLossPercent: yesterdayGainLossPercent,
    totalGainLoss: totalGainLoss,
    totalGainLossPercent: totalGainLossPercent,
    marketDate: marketDate,
    positionsCount: positions.length,
    sessionHistory: history,
  );
});
