import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import 'market_providers.dart';
import 'market_sync_service.dart';
import '../../data/repositories/market_repository.dart';
import 'widgets/stock_list_tile.dart';

/// Écran Marché affichant l'ensemble de la cote BRVM avec un design épuré et minimaliste
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Synchronisation en arrière-plan des cotations
    ref.watch(marketSyncServiceProvider);

    final stocks = ref.watch(filteredMarketStocksProvider);
    final selectedFilter = ref.watch(marketFilterProvider);
    final isRefreshing = ref.watch(isMarketRefreshingProvider);
    final lastUpdated = ref.watch(lastMarketUpdateTimeProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(marketStocksProvider.notifier).refreshLiveQuotes(),
          child: ResponsiveCenter(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête avec titre 'Marché', heure de mise à jour et bouton Actualiser
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Marché',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isRefreshing
                                ? 'Actualisation en direct...'
                                : 'Mis à jour à ${DateFormat('HH:mm').format(lastUpdated)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Tooltip(
                        message: 'Rafraîchir les cotations',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isRefreshing
                                ? null
                                : () async {
                                    final result = await ref
                                        .read(marketStocksProvider.notifier)
                                        .refreshLiveQuotes();
                                    if (context.mounted) {
                                      final String message;
                                      final IconData icon;
                                      final Color bannerColor;

                                      if (result.source == RefreshSource.liveBrvm) {
                                        if (result.firestoreUpdated) {
                                          message = 'Cotations BRVM récupérées en direct et synchronisées dans Firestore (${result.stocks.length} titres)';
                                          icon = Icons.cloud_done;
                                          bannerColor = const Color(0xFF1B4332);
                                        } else {
                                          message = 'Cotations en direct récupérées (sauvegarde Firestore en attente)';
                                          icon = Icons.warning_amber_rounded;
                                          bannerColor = Colors.orange.shade800;
                                        }
                                      } else {
                                        message = 'Site BRVM injoignable : cours rechargés depuis Firestore';
                                        icon = Icons.cloud_download_outlined;
                                        bannerColor = const Color(0xFF2C3E50);
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(icon, color: Colors.white, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  message,
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: bannerColor,
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isRefreshing)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isRefreshing ? 'Actualisation...' : 'Actualiser',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isRefreshing
                                          ? AppColors.textSecondary
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Petit label 'Rechercher un titre'
                  const Text(
                    'Rechercher un titre',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Champ de recherche avec placeholder 'Code ou nom'
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(marketSearchQueryProvider.notifier).updateQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Code ou nom',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textTertiary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(marketSearchQueryProvider.notifier).clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3 onglets de filtres dans un conteneur arrondi : 'Tous', 'Hausses', 'Baisses'
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterTab(
                            label: 'Tous',
                            filter: StockFilter.all,
                            isSelected: selectedFilter == StockFilter.all,
                          ),
                        ),
                        Expanded(
                          child: _buildFilterTab(
                            label: 'Hausses',
                            filter: StockFilter.gainers,
                            isSelected: selectedFilter == StockFilter.gainers,
                          ),
                        ),
                        Expanded(
                          child: _buildFilterTab(
                            label: 'Baisses',
                            filter: StockFilter.losers,
                            isSelected: selectedFilter == StockFilter.losers,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Liste des titres dans un conteneur style carte avec bordure subtile
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: stocks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.textTertiary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Aucun titre correspondant',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Vérifiez l\'orthographe ou changez de filtre.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < stocks.length; i++)
                                StockListTile(
                                  stock: stocks[i],
                                  onTap: () => context.push('/stock/${stocks[i].code}'),
                                  showDivider: true,
                                ),
                              // Au bas de la liste, points de suspension (...) et icône menu ⋯
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '...',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Icon(
                                      Icons.more_horiz,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Texte de pied de page
                  const Text(
                    'Cours indicatifs, sans garantie. Mis à jour après la clôture.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Onglet de filtre personnalisé avec fond blanc si sélectionné (comme dans la maquette)
  Widget _buildFilterTab({
    required String label,
    required StockFilter filter,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(marketFilterProvider.notifier).selectFilter(filter);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
