import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../market/market_providers.dart';
import '../market/market_sync_service.dart';
import 'portfolio_providers.dart';
import 'widgets/portfolio_summary_card.dart';
import 'widgets/position_list_tile.dart';

/// Écran principal du Portefeuille (Accueil) selon le design épuré sans AppBar
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active le service de synchronisation continue en arrière-plan
    ref.watch(marketSyncServiceProvider);

    final summary = ref.watch(portfolioSummaryProvider);
    final positions = ref.watch(portfolioPositionsProvider);

    // Maintien des références aux providers existants
    ref.watch(currentSessionStatusProvider);
    ref.watch(lastMarketUpdateTimeProvider);
    ref.watch(isMarketRefreshingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0), // Fond beige élégant du mockup
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(marketStocksProvider.notifier).refreshLiveQuotes(),
          child: ResponsiveCenter(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Synthèse du portefeuille : en-tête épuré, pills de gains, solde disponible
                  PortfolioSummaryCard(summary: summary),
                  const SizedBox(height: 16),

                  // Carte contenant la liste des positions
                  if (positions.isEmpty)
                    _buildEmptyState(context)
                  else
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                      color: Colors.white,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (int i = 0; i < positions.length; i++)
                            PositionListTile(
                              position: positions[i],
                              showDivider: i < positions.length - 1,
                              onTap: () => context.push('/stock/${positions[i].stockCode}'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 56,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune position active',
              style: TextStyle(
                fontSize: 17,
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
    );
  }
}
