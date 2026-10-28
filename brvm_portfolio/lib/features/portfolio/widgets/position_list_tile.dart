import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../../../core/models/position.dart';

/// Ligne d'affichage d'une position détenue dans le portefeuille
class PositionListTile extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;

  const PositionListTile({
    super.key,
    required this.position,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dailyColor = position.dailyVariation.financialColor;
    final totalGainColor = position.totalGainLoss.financialColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // Ligne supérieure : Code, Nom et Valorisation totale
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge mnémonique
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      position.stockCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nom du titre et quantité
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.stockName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${position.quantity} actions • PRU : ${formatFCFA(position.pru.round())}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Valorisation totale actuelle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatFCFA(position.totalValuation),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cours : ${formatFCFA(position.currentPrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Séparateur fin
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),

              // Ligne inférieure : Performance du jour et Plus-value latente totale
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Variation journalière
                  Row(
                    children: [
                      const Text(
                        'Jour : ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        position.dailyVariation.toVariationPercent(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dailyColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${position.dailyGainLoss.toVariationFCFA()})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: dailyColor,
                        ),
                      ),
                    ],
                  ),

                  // Plus-value latente globale
                  Row(
                    children: [
                      const Text(
                        'PV latente : ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: position.totalGainLoss.financialColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${position.totalGainLoss.toVariationFCFA()} (${position.totalGainLossPercent.toVariationPercent()})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: totalGainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
