import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../../../core/models/operation.dart';

/// Ligne d'affichage d'une opération financière dans l'historique
class OperationListTile extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const OperationListTile({
    super.key,
    required this.operation,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Détermination de l'icône et des couleurs selon le type
    IconData icon;
    Color iconColor;
    Color iconBg;
    String title;
    String subtitle;
    bool isCredit = false;

    switch (operation.type) {
      case OperationType.achat:
        icon = Icons.shopping_bag_outlined;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withValues(alpha: 0.1);
        title = 'Achat ${operation.stockCode ?? ''}';
        subtitle = '${operation.quantity} actions @ ${formatFCFA(operation.unitPrice ?? 0)}';
        if (operation.fees > 0) subtitle += ' • Frais : ${formatFCFA(operation.fees)}';
        isCredit = false;
        break;

      case OperationType.vente:
        icon = Icons.sell_outlined;
        iconColor = const Color(0xFF6A1B9A); // Violet
        iconBg = const Color(0xFF6A1B9A).withValues(alpha: 0.1);
        title = 'Vente ${operation.stockCode ?? ''}';
        subtitle = '${operation.quantity} actions @ ${formatFCFA(operation.unitPrice ?? 0)}';
        if (operation.fees > 0) subtitle += ' • Frais : ${formatFCFA(operation.fees)}';
        isCredit = true;
        break;

      case OperationType.depot:
        icon = Icons.arrow_downward_rounded;
        iconColor = AppColors.gain;
        iconBg = AppColors.gainLight;
        title = 'Dépôt d\'espèces SGI';
        subtitle = operation.notes ?? 'Alimentation du compte';
        isCredit = true;
        break;

      case OperationType.retrait:
        icon = Icons.arrow_upward_rounded;
        iconColor = AppColors.loss;
        iconBg = AppColors.lossLight;
        title = 'Retrait de fonds';
        subtitle = operation.notes ?? 'Virement vers compte bancaire';
        isCredit = false;
        break;
    }

    final amountStr = isCredit
        ? '+${formatFCFA(operation.netAmount)}'
        : '-${formatFCFA(operation.netAmount)}';
    final amountColor = isCredit ? AppColors.gain : AppColors.loss;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Badge icône
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Détails : Titre, sous-titre et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      operation.date.toShortDate(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Montant net
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Net',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
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
