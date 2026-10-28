import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import 'history_providers.dart';
import 'widgets/operation_list_tile.dart';
import 'widgets/reconciliation_card.dart';

/// Écran Historique listant toutes les opérations financières et le rapprochement SGI
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(filteredOperationsProvider);
    final selectedFilter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Opérations'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle opération',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.push('/operation/add'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Section Rapprochement de solde SGI en haut
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: ReconciliationCard(),
            ),
          ),

          // Barre de filtres par type d'opération
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: HistoryFilter.values.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(historyFilterProvider.notifier).selectFilter(filter);
                        },
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // En-tête de section avec compteur
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Journal des ordres et flux',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${operations.length} ${operations.length > 1 ? 'opérations' : 'opération'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des opérations ou affichage vide
          if (operations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune opération trouvée',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Modifiez votre filtre ou saisissez une nouvelle opération.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/operation/add'),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une opération'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final op = operations[index];
                  return OperationListTile(
                    operation: op,
                    onTap: () {
                      context.push('/operation/${op.id}/edit');
                    },
                  );
                },
                childCount: operations.length,
              ),
            ),

          // Marge basse
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}
