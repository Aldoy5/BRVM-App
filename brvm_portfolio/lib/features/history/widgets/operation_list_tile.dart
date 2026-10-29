import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../core/models/operation.dart';

/// Ligne d'affichage d'une opération financière dans l'historique
class OperationListTile extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDivider;

  const OperationListTile({
    super.key,
    required this.operation,
    this.onTap,
    this.onDelete,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    // Détection d'une opération d'ajustement liée aux écarts SGI
    final isAdjustment = operation.notes != null &&
        (operation.notes!.toLowerCase().contains('écart') ||
            operation.notes!.toLowerCase().contains('ajust'));

    final String typeName;
    if (isAdjustment) {
      typeName = 'Ajust.';
    } else {
      switch (operation.type) {
        case OperationType.achat:
          typeName = 'Achat';
          break;
        case OperationType.vente:
          typeName = 'Vente';
          break;
        case OperationType.depot:
          typeName = 'Dépôt';
          break;
        case OperationType.retrait:
          typeName = 'Retrait';
          break;
      }
    }

    final stockCode = operation.type.isStockOperation ? operation.stockCode : null;

    final day = operation.date.day.toString().padLeft(2, '0');
    final month = operation.date.month.toString().padLeft(2, '0');
    final dateStr = '$day/$month';

    final String detail;
    if (isAdjustment) {
      final noteStr = (operation.notes != null && operation.notes!.isNotEmpty)
          ? ' · ${operation.notes}'
          : '';
      detail = '$dateStr$noteStr';
    } else if (operation.type.isStockOperation) {
      final qty = operation.quantity ?? 0;
      final price = AppFormatters.formatInteger(operation.unitPrice ?? 0);
      detail = '$qty × $price · $dateStr';
    } else {
      detail = dateStr;
    }

    final bool isCredit =
        operation.type == OperationType.vente || operation.type == OperationType.depot;

    final formattedAmount = AppFormatters.formatInteger(operation.netAmount);
    final amountStr = isCredit ? '+$formattedAmount' : '-$formattedAmount';
    const amountColor = AppColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: typeName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (stockCode != null && stockCode.isNotEmpty) ...[
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: stockCode,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amountStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
