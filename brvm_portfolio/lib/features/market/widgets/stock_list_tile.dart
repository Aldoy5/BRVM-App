import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/models/stock.dart';

/// Ligne d'affichage minimaliste d'une action pour la liste de cotation du marché
class StockListTile extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final bool showDivider;

  const StockListTile({
    super.key,
    required this.stock,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final variation = stock.dailyVariation;

    // Détermination de la couleur selon le signe : vert pour +, rouge pour -, noir pour 0
    final Color variationColor;
    if (variation > 0.0001) {
      variationColor = AppColors.gain;
    } else if (variation < -0.0001) {
      variationColor = AppColors.loss;
    } else {
      variationColor = AppColors.textPrimary;
    }

    // Formatage de la variation en pourcentage (+0,8 %, -1,95 %, 0,0 %)
    final String variationText;
    if (variation.abs() < 0.0001) {
      variationText = '0,0 %';
    } else {
      final sign = variation > 0 ? '+' : '';
      final numStr = NumberFormat('#,##0.0#', 'fr_FR').format(variation);
      variationText = '$sign$numStr %';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Côté gauche : Code (gras) + Nom (plus clair, plus petit, en ligne)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: stock.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(
                            text: stock.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Côté droit : Cours (gras, aligné à droite) + Variation % dessous en couleur
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stock.currentPrice.toFormattedString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        variationText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: variationColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}
