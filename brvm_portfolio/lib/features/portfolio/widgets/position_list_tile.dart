import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../core/models/position.dart';

/// Ligne d'affichage d'une position détenue dans le portefeuille selon le design mockup
class PositionListTile extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;
  final bool showDivider;

  const PositionListTile({
    super.key,
    required this.position,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final dailyGainLoss = position.dailyGainLoss;
    final dailyVariation = position.dailyVariation;

    // Couleur financière (vert gain / rouge perte / gris neutre)
    final Color dailyColor = dailyGainLoss > 0
        ? AppColors.gain
        : (dailyGainLoss < 0 ? AppColors.loss : AppColors.neutral);

    // Formatage de la variation journalière en FCFA (+12 000)
    final String amountSign = dailyGainLoss > 0 ? '+' : (dailyGainLoss < 0 ? '-' : '');
    final String dailyAmountStr = '$amountSign${AppFormatters.formatInteger(dailyGainLoss.abs())}';

    // Formatage du pourcentage (+0,8 %)
    final String pctSign = dailyVariation > 0 ? '+' : (dailyVariation < 0 ? '-' : '');
    final String pctValue = NumberFormat('0.00', 'fr_FR').format(dailyVariation.abs());
    final String dailyPctStr = '$pctSign$pctValue %';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Côté gauche : ticker gras + 'N titres' plus clair inline, montant investi en dessous
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: position.stockCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: '  ${position.quantity} titres',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatFCFA(position.investedAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Côté droit : variation du jour en montant (+12 000, gras, coloré) et en % (+0,8 %, coloré, en dessous)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dailyAmountStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dailyColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dailyPctStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: dailyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
