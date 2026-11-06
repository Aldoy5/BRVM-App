import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../core/models/portfolio_summary.dart';

/// Carte affichant l'historique de performance du portefeuille séance par séance (Cas 3).
class PortfolioSessionHistoryCard extends StatefulWidget {
  final List<DailySessionPerformance> history;

  const PortfolioSessionHistoryCard({
    super.key,
    required this.history,
  });

  @override
  State<PortfolioSessionHistoryCard> createState() =>
      _PortfolioSessionHistoryCardState();
}

class _PortfolioSessionHistoryCardState
    extends State<PortfolioSessionHistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) return const SizedBox.shrink();

    // Par défaut affiche les 2 premières séances (Aujourd'hui et Hier), et tout si déplié
    final displayedList = _isExpanded
        ? widget.history
        : widget.history.take(2).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête cliquable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Historique des séances (Jour par jour)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        _isExpanded ? 'Réduire' : 'Voir plus',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Liste des séances journalières
          for (int i = 0; i < displayedList.length; i++) ...[
            _buildSessionRow(displayedList[i]),
            if (i < displayedList.length - 1)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionRow(DailySessionPerformance session) {
    final isGain = session.isGaining;
    final isLoss = session.isLosing;

    final Color statusColor = isGain
        ? AppColors.gain
        : (isLoss ? AppColors.loss : AppColors.neutral);

    final Color bgColor = isGain
        ? AppColors.gainLight
        : (isLoss ? AppColors.lossLight : AppColors.neutralLight);

    final String gainStr = AppFormatters.formatVariationAmount(session.gainLoss);
    final String varPctStr =
        AppFormatters.formatPercentWithSign(session.variationPercent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gauche : Label de date + Valorisation de clôture
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Valorisation : ${formatFCFA(session.valuation)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          // Droite : Badge Gain / Perte de la séance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$gainStr ($varPctStr)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
