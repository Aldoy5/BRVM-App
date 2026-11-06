import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../market/market_providers.dart';
import '../market/market_sync_service.dart';
import 'portfolio_display_mode.dart';
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
    final displayMode = ref.watch(portfolioDisplayModeProvider);

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
                  // Synthèse du portefeuille : en-tête épuré, toggle, pill de gains, solde disponible
                  PortfolioSummaryCard(summary: summary),
                  const SizedBox(height: 20),

                  // Carte contenant la liste des positions
                  if (positions.isEmpty)
                    _buildEmptyState(context)
                  else ...[
                    // En-tête de section avec indication du mode actif
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MES TITRES (${positions.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            displayMode == PortfolioDisplayMode.session
                                ? 'Affichage : Performance séance'
                                : 'Affichage : Plus-value globale',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
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
                          _ImportBanner(onTap: () => context.push('/import-statement')),
                          for (int i = 0; i < positions.length; i++)
                            PositionListTile(
                              position: positions[i],
                              portfolioTotalValuation: summary.totalValuation,
                              displayMode: displayMode,
                              showDivider: i < positions.length - 1,
                              onTap: () => context.push('/stock/${positions[i].stockCode}'),
                            ),
                        ],
                      ),
                    ),
                  ],
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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/import-statement'),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Importer un relevé PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière compacte d'import PDF dans la carte des positions
class _ImportBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ImportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        child: const Row(
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Importer un relevé de compte BICI Bourse',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
