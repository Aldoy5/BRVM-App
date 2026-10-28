import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import 'market_providers.dart';
import 'market_sync_service.dart';
import 'widgets/stock_list_tile.dart';

/// Écran Marché affichant l'ensemble de la cote BRVM avec recherche, tri et mise à jour continue
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stocks = ref.watch(filteredMarketStocksProvider);
    final allStocks = ref.watch(marketStocksProvider);
    final selectedFilter = ref.watch(marketFilterProvider);
    final selectedSort = ref.watch(marketSortProvider);
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
            Text(
              'Marché BRVM (${allStocks.length} titres)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
                      ? 'En direct différé 15 min • $formattedTime'
                      : 'Séance fermée • $formattedTime',
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
          IconButton(
            tooltip: 'Actualiser la cote en direct',
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(marketSearchQueryProvider.notifier).updateQuery(val);
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un titre (ex: SNTS, SGBC, CORIS)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(marketSearchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre de filtres et de tri
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                // Filtres de statut
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: StockFilter.values.map((filter) {
                        final isSelected = selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter.label),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(marketFilterProvider.notifier).selectFilter(filter);
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

                // Menu de tri
                PopupMenuButton<StockSort>(
                  icon: const Icon(Icons.sort, color: AppColors.primary),
                  tooltip: 'Trier la cote',
                  initialValue: selectedSort,
                  onSelected: (sort) {
                    ref.read(marketSortProvider.notifier).selectSort(sort);
                  },
                  itemBuilder: (context) => StockSort.values.map((sort) {
                    return PopupMenuItem<StockSort>(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            selectedSort == sort
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: selectedSort == sort ? AppColors.primary : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 10),
                          Text(sort.label, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Liste des titres avec pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(marketStocksProvider.notifier).refreshLiveQuotes(),
              child: stocks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aucun titre correspondant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Vérifiez l\'orthographe ou changez de filtre.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final stock = stocks[index];
                        return StockListTile(
                          stock: stock,
                          onTap: () => context.push('/stock/${stock.code}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
