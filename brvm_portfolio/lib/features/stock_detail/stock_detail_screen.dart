import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/formatters.dart';
import '../market/market_providers.dart';
import '../portfolio/portfolio_providers.dart';
import 'widgets/price_chart.dart';

/// Écran Fiche Titre détaillée pour une action BRVM
class StockDetailScreen extends ConsumerWidget {
  final String stockCode;

  const StockDetailScreen({
    super.key,
    required this.stockCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(stockByCodeProvider(stockCode));
    final position = ref.watch(positionByStockCodeProvider(stockCode));

    if (stock == null) {
      return Scaffold(
        appBar: AppBar(title: Text(stockCode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.loss),
              const SizedBox(height: 12),
              Text(
                'Titre "$stockCode" introuvable',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour à la liste'),
              ),
            ],
          ),
        ),
      );
    }

    final variationColor = stock.dailyVariation.financialColor;
    final variationBg = stock.dailyVariation.financialBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('${stock.code} - ${stock.name}'),
        actions: [
          IconButton(
            tooltip: 'Partager le cours',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              context.showAppSnackBar('Cours partagé : ${stock.name} à ${formatFCFA(stock.currentPrice)}');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête : Titre, Secteur et Cours
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stock.code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stock.sector,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    stock.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grand cours actuel + Variation
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatFCFA(stock.currentPrice),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: variationBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              stock.isGaining
                                  ? Icons.arrow_drop_up_rounded
                                  : (stock.isLosing
                                      ? Icons.arrow_drop_down_rounded
                                      : Icons.remove),
                              size: 18,
                              color: variationColor,
                            ),
                            Text(
                              '${stock.dailyVariation.toVariationPercent()} (${stock.variationAmount.toVariationFCFA()})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: variationColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dernière cotation : ${stock.lastUpdated.toDateTimeString()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mini-graphique de tendance
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Évolution récente du cours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '7 dernières séances',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PriceChart(
                    prices: stock.historicalPrices,
                    isGaining: stock.isGaining,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Caractéristiques de la séance
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques de la séance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Cours Veille', formatFCFA(stock.previousClosePrice)),
                      ),
                      Expanded(
                        child: _buildStatItem('Cours Ouverture', formatFCFA(stock.openingPrice > 0 ? stock.openingPrice : stock.previousClosePrice)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Cours Clôture / Actuel', formatFCFA(stock.currentPrice)),
                      ),
                      Expanded(
                        child: _buildStatItem('Volume échangé', stock.volume.toFormattedString()),
                      ),
                    ],
                  ),
                  if (stock.dayHigh > 0 && stock.dayLow > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem('Plus haut (Jour)', formatFCFA(stock.dayHigh)),
                        ),
                        Expanded(
                          child: _buildStatItem('Plus bas (Jour)', formatFCFA(stock.dayLow)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Section "Ma Position dans ce titre" (si détenu ou non)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ma position en portefeuille',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (position != null) ...[
                    // Carte détaillée de la position
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPositionMetric('Titres détenus', '${position.quantity} actions'),
                              _buildPositionMetric('Prix Moyen (PRU)', formatFCFA(position.pru.round())),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPositionMetric('Valorisation', formatFCFA(position.totalValuation)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Plus-value latente',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${position.totalGainLoss.toVariationFCFA()} (${position.totalGainLossPercent.toVariationPercent()})',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: position.totalGainLoss.financialColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Message titre non détenu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.textSecondary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous ne possédez pas encore de ligne sur ce titre.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton Vendre (disponible si position > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '/operation/add?stockCode=${stock.code}&type=vente',
                    );
                  },
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.loss),
                  label: const Text(
                    'Vendre',
                    style: TextStyle(color: AppColors.loss),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.loss, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Bouton Acheter (Action principale)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '/operation/add?stockCode=${stock.code}&type=achat',
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Acheter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
