import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../../../core/models/portfolio_summary.dart';

/// Carte de synthèse financière du portefeuille avec affichage Hero
class PortfolioSummaryCard extends StatelessWidget {
  final PortfolioSummary summary;

  const PortfolioSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Carte principale Hero
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Bleu nuit BRVM
                Color(0xFF0D1B48),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de carte : Label et badge liquidités
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VALORISATION PORTEFEUILLE',
                    style: TextStyle(
                      color: Color(0xFFC5CAE9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${summary.positionsCount} ${summary.positionsCount > 1 ? 'lignes' : 'ligne'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Grand chiffre HERO : Valeur totale des actions
              Text(
                formatFCFA(summary.totalValuation),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 18),

              // Séparateur fin
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 16),

              // Grille des deux métriques clés : Variation du jour & Plus-value totale
              Row(
                children: [
                  // 1. Variation du jour
                  Expanded(
                    child: _buildMetricItem(
                      label: 'Variation du jour',
                      amount: summary.dailyGainLoss,
                      percent: summary.dailyGainLossPercent,
                      isGain: summary.isGainingDaily,
                      isLoss: summary.isLosingDaily,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  // 2. Plus-value totale latente
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: _buildMetricItem(
                        label: 'Plus-value totale',
                        amount: summary.totalGainLoss,
                        percent: summary.totalGainLossPercent,
                        isGain: summary.isGainingTotal,
                        isLoss: summary.isLosingTotal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rubrique Solde Espèces disponible & Patrimoine total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.savings_outlined,
                          size: 18,
                          color: Color(0xFFC5CAE9),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Solde espèces disponible',
                              style: TextStyle(
                                color: Color(0xFFC5CAE9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formatFCFA(summary.cashBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Patrimoine total',
                          style: TextStyle(
                            color: Color(0xFFC5CAE9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatFCFA(summary.totalWealth),
                          style: const TextStyle(
                            color: Color(0xFF81D4FA),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Mention obligatoire "Cours au [date]" sous la carte, visible en permanence
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                '${summary.marketDate.toMarketQuoteMention()} • Clôture officielle BRVM',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required int amount,
    required double percent,
    required bool isGain,
    required bool isLoss,
  }) {
    final Color badgeColor = isGain
        ? const Color(0xFF4CAF50)
        : (isLoss ? const Color(0xFFEF5350) : const Color(0xFFB0BEC5));

    final IconData icon = isGain
        ? Icons.arrow_drop_up_rounded
        : (isLoss ? Icons.arrow_drop_down_rounded : Icons.remove);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC5CAE9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          amount.toVariationFCFA(),
          style: TextStyle(
            color: badgeColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: badgeColor),
            Text(
              percent.toVariationPercent(),
              style: TextStyle(
                color: badgeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
