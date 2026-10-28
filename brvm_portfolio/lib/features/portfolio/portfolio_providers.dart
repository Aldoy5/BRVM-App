import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      positions.add(
        Position(
          stockCode: code,
          stockName: stockName,
          quantity: qty,
          pru: pru,
          currentPrice: currentPrice,
          previousClosePrice: prevPrice,
          dailyVariation: dailyVariation,
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

  int totalValuation = 0;
  int totalInvested = 0;
  int dailyGainLoss = 0;

  for (final pos in positions) {
    totalValuation += pos.totalValuation;
    totalInvested += pos.investedAmount;
    dailyGainLoss += pos.dailyGainLoss;
  }

  final totalGainLoss = totalValuation - totalInvested;
  final totalGainLossPercent = totalInvested > 0
      ? (totalGainLoss / totalInvested) * 100.0
      : 0.0;

  final previousDayValuation = totalValuation - dailyGainLoss;
  final dailyGainLossPercent = previousDayValuation > 0
      ? (dailyGainLoss / previousDayValuation) * 100.0
      : 0.0;

  return PortfolioSummary(
    totalValuation: totalValuation,
    cashBalance: cashBalance,
    dailyGainLoss: dailyGainLoss,
    dailyGainLossPercent: dailyGainLossPercent,
    totalGainLoss: totalGainLoss,
    totalGainLossPercent: totalGainLossPercent,
    marketDate: ref.watch(lastMarketUpdateTimeProvider),
    positionsCount: positions.length,
  );
});
