import '../../core/extensions.dart';
import '../../core/models/operation.dart';
import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import 'history_providers.dart';
import 'widgets/operation_list_tile.dart';
import 'widgets/reconciliation_card.dart';

/// Écran Historique listant toutes les opérations financières et le rapprochement SGI
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Operation operation) {
    final title = operation.type.label;
    final code = operation.stockCode != null ? ' ${operation.stockCode}' : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'opération'),
        content: Text(
          'Voulez-vous vraiment supprimer cette opération ($title$code) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.loss,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(operationsProvider.notifier).deleteOperation(operation.id);
              if (context.mounted) {
                context.showAppSnackBar('Opération supprimée', isSuccess: true);
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(filteredOperationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grand titre 'Historique' en gras
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Historique',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Section de rapprochement avec la SGI
              const ReconciliationCard(),

              const SizedBox(height: 4),

              // Carte blanche englobant toutes les opérations
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: Colors.white,
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border, width: 0.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: operations.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: AppColors.textTertiary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Aucune opération enregistrée',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < operations.length; i++) ...[
                              Dismissible(
                                key: Key('op-${operations[i].id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: AppColors.loss,
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  final title = operations[i].type.label;
                                  final code = operations[i].stockCode != null ? ' ${operations[i].stockCode}' : '';
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Supprimer l\'opération'),
                                      content: Text(
                                        'Voulez-vous vraiment supprimer cette opération ($title$code) ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.loss,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                },
                                onDismissed: (_) {
                                  ref.read(operationsProvider.notifier).deleteOperation(operations[i].id);
                                  context.showAppSnackBar('Opération supprimée', isSuccess: true);
                                },
                                child: OperationListTile(
                                  operation: operations[i],
                                  onTap: () {
                                    context.push('/operation/${operations[i].id}/edit');
                                  },
                                  onDelete: () => _confirmDelete(context, ref, operations[i]),
                                ),
                              ),
                              if (i < operations.length - 1)
                                const Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: AppColors.divider,
                                ),
                            ],
                          ],
                        ),
                ),
              ),

              // Marge basse pour le défilement au-dessus de la barre de navigation
              const SizedBox(height: 80),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
