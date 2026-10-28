import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../market/market_providers.dart';
import '../market/market_sync_service.dart';
import 'portfolio_providers.dart';
import 'widgets/portfolio_summary_card.dart';
import 'widgets/position_list_tile.dart';

/// Écran principal du Portefeuille (Accueil) avec mise à jour continue des cours
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active le service de synchronisation continue en arrière-plan
    ref.watch(marketSyncServiceProvider);

    final summary = ref.watch(portfolioSummaryProvider);
    final positions = ref.watch(portfolioPositionsProvider);
    final sessionStatus = ref.watch(currentSessionStatusProvider);
    final lastUpdated = ref.watch(lastMarketUpdateTimeProvider);
    final isRefreshing = ref.watch(isMarketRefreshingProvider);

    final timeFormatter = DateFormat('HH:mm:ss', 'fr_FR');
    final formattedTime = timeFormatter.format(lastUpdated.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon Portefeuille',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sessionStatus.isLive ? AppColors.gain : AppColors.neutral,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  sessionStatus.isLive
                      ? 'En direct • $formattedTime'
                      : 'Séance clôturée • $formattedTime',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: sessionStatus.isLive ? AppColors.gain : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Bouton d'actualisation manuelle immédiate
          IconButton(
            tooltip: 'Actualiser les cours en direct',
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: isRefreshing
                ? null
                : () => ref.read(marketStocksProvider.notifier).refreshLiveQuotes(),
          ),
          IconButton(
            tooltip: 'Nouvelle opération',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.push('/operation/add'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketStocksProvider.notifier).refreshLiveQuotes(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Section Résumé / Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: PortfolioSummaryCard(summary: summary),
              ),
            ),

            // En-tête de la liste des positions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes Positions (${positions.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Tri : Valorisation',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Liste des positions ou état vide
            if (positions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune position active',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enregistrez un premier achat d\'actions BRVM pour commencer le suivi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/operation/add?type=achat'),
                          icon: const Icon(Icons.add),
                          label: const Text('Enregistrer un achat'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final position = positions[index];
                      return PositionListTile(
                        position: position,
                        onTap: () => context.push('/stock/${position.stockCode}'),
                      );
                    },
                    childCount: positions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
