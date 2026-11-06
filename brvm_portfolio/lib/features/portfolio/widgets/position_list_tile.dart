import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../core/models/position.dart';
import '../portfolio_display_mode.dart';

/// Ligne d'affichage d'une position détenue dans le portefeuille.
/// Présente :
/// - Le ticker, le nombre de titres et le nom du titre
/// - Le détail des prix selon le mode (Total: PRU/Cours, Séance: Cours/Veille, Hier: Veille/Avant-veille)
/// - La valorisation actuelle
/// - La plus-value / moins-value (totale, séance ou hier selon le mode) avec label explicite
/// - Le poids du titre dans le portefeuille avec une barre de progression colorée (vert/rouge).
class PositionListTile extends StatelessWidget {
  final Position position;
  final int portfolioTotalValuation;
  final PortfolioDisplayMode displayMode;
  final VoidCallback? onTap;
  final bool showDivider;

  const PositionListTile({
    super.key,
    required this.position,
    this.portfolioTotalValuation = 0,
    this.displayMode = PortfolioDisplayMode.total,
    this.onTap,
    this.showDivider = true,
  });

  /// Poids relatif dans le portefeuille (entre 0.0 et 1.0)
  double get weightRatio {
    if (portfolioTotalValuation <= 0 || position.totalValuation <= 0) return 0.0;
    return (position.totalValuation / portfolioTotalValuation).clamp(0.0, 1.0);
  }

  /// Poids en pourcentage (0.0 à 100.0)
  double get weightPercent => weightRatio * 100.0;

  @override
  Widget build(BuildContext context) {
    final isSession = displayMode == PortfolioDisplayMode.session;
    final isYesterday = displayMode == PortfolioDisplayMode.yesterday;

    // Gain/Perte et variation selon le mode actif
    final int gainLoss;
    final double gainLossPct;
    final String modePrefix;
    final String priceDetails;

    if (isYesterday) {
      gainLoss = position.yesterdayGainLoss;
      gainLossPct = position.yesterdayVariation;
      modePrefix = 'Hier: ';
      priceDetails =
          '${position.stockName} • Veille ${AppFormatters.formatInteger(position.previousClosePrice)} F • Avant-veille ${AppFormatters.formatInteger(position.effectiveDayBeforeYesterdayPrice)} F';
    } else if (isSession) {
      gainLoss = position.dailyGainLoss;
      gainLossPct = position.dailyVariation;
      modePrefix = 'Jour: ';
      priceDetails =
          '${position.stockName} • Cours ${AppFormatters.formatInteger(position.currentPrice)} F • Veille ${AppFormatters.formatInteger(position.previousClosePrice)} F';
    } else {
      gainLoss = position.totalGainLoss;
      gainLossPct = position.totalGainLossPercent;
      modePrefix = 'Total: ';
      priceDetails =
          '${position.stockName} • PRU ${AppFormatters.formatInteger(position.pru.round())} F • Cours ${AppFormatters.formatInteger(position.currentPrice)} F';
    }

    final isGain = gainLoss > 0;
    final isLoss = gainLoss < 0;

    // Couleur financière : vert si gain, rouge si perte, gris neutre si équilibré
    final Color statusColor = isGain
        ? AppColors.gain
        : (isLoss ? AppColors.loss : AppColors.neutral);

    // Formatage de la plus-value / moins-value
    final String gainLossStr = AppFormatters.formatVariationAmount(gainLoss);
    final String gainLossPctStr = AppFormatters.formatPercentWithSign(gainLossPct);

    // Formatage du poids (ex: "15,2 %")
    final String weightStr = '${NumberFormat('0.0', 'fr_FR').format(weightPercent)} %';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 1. Ligne principale : Ticker / Titres à gauche | Valorisation / Gain-Perte à droite ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gauche : Ticker gras + badge quantité + nom et repères de prix
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                position.stockCode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border, width: 0.6),
                                ),
                                child: Text(
                                  '${position.quantity} titres',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            priceDetails,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Droite : Valorisation actuelle et Gain / Perte avec libellé explicite
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatFCFA(position.totalValuation),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              modePrefix,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              '$gainLossStr ($gainLossPctStr)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ─── 2. Barre de progression du poids dans le portefeuille ───
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 5,
                          child: LinearProgressIndicator(
                            value: weightRatio,
                            backgroundColor: AppColors.neutralLight,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$weightStr du portefeuille',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
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
