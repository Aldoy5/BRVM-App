import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../history_providers.dart';

/// Carte de rapprochement bancaire / SGI
/// Permet de confronter le solde réel de l'avis de la SGI avec le solde calculé par l'application
class ReconciliationCard extends ConsumerWidget {
  const ReconciliationCard({super.key});

  void _showEditSgiBalanceDialog(BuildContext context, WidgetRef ref, int currentBalance) {
    final controller = TextEditingController(text: currentBalance.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Solde réel SGI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Entrez le solde espèces disponible indiqué sur votre dernier relevé ou portail SGI :',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Solde réel (FCFA)',
                  suffixText: 'FCFA',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text.trim());
                if (val != null) {
                  ref.read(sgiDeclaredBalanceProvider.notifier).updateBalance(val);
                  Navigator.of(dialogCtx).pop();
                  context.showAppSnackBar('Solde SGI mis à jour', isSuccess: true);
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciliation = ref.watch(reconciliationProvider);
    final isReconciled = reconciliation.isReconciled;
    final diff = reconciliation.difference;

    final Color statusColor = isReconciled
        ? AppColors.gain
        : (diff > 0 ? const Color(0xFF1976D2) : AppColors.loss);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isReconciled ? AppColors.gain.withValues(alpha: 0.5) : AppColors.border,
          width: isReconciled ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre avec statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Rapprochement Solde SGI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isReconciled
                            ? Icons.check_circle_outline
                            : (diff > 0 ? Icons.info_outline : Icons.warning_amber_rounded),
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isReconciled ? 'Synchronisé' : 'Écart détecté',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Comparaison des deux soldes
            Row(
              children: [
                // 1. Mon solde SGI déclaré
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditSgiBalanceDialog(
                      context,
                      ref,
                      reconciliation.sgiDeclaredBalance,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Mon solde SGI',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.edit, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatFCFA(reconciliation.sgiDeclaredBalance),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Ce que l'app a calculé
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'L\'app a calculé',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatFCFA(reconciliation.appCalculatedBalance),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ligne de l'écart
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReconciled
                        ? 'Écart : 0 FCFA (Parfaite concordance)'
                        : 'Écart : ${diff.toVariationFCFA()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    isReconciled
                        ? 'Tout est exact'
                        : (diff > 0 ? 'Dividendes à saisir ?' : 'Frais non saisis ?'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
