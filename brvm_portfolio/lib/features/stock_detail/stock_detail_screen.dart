import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/formatters.dart';
import '../market/market_providers.dart';
import '../portfolio/portfolio_providers.dart';
import 'widgets/price_chart.dart';

/// Écran Fiche Titre détaillée pour une action BRVM
class StockDetailScreen extends ConsumerStatefulWidget {
  final String stockCode;

  const StockDetailScreen({
    super.key,
    required this.stockCode,
  });

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  String _selectedPeriod = '1M';

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(stockByCodeProvider(widget.stockCode));
    final position = ref.watch(positionByStockCodeProvider(widget.stockCode));

    if (stock == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F4EE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '← Marché',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.loss),
                      const SizedBox(height: 12),
                      Text(
                        'Titre "${widget.stockCode}" introuvable',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A4D),
                        ),
                        child: const Text('Retour à la liste'),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final sign = stock.dailyVariation > 0 ? '+' : (stock.dailyVariation < 0 ? '-' : '');
    final varAmount = '$sign${stock.variationAmount.abs().toFormattedString()}';
    final varPct = '($sign${stock.dailyVariation.abs().toStringAsFixed(1).replaceAll('.', ',')} %)';
    final variationText = '$varAmount $varPct aujourd’hui';
    final variationColor = stock.dailyVariation > 0
        ? const Color(0xFF1F7A4D)
        : (stock.dailyVariation < 0 ? AppColors.loss : const Color(0xFF757575));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lien retour "← Marché"
              GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '← Marché',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ),
              ),

              // Titre : Code · Nom
              Text(
                '${stock.code} · ${stock.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1B1F),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Grand cours actuel (ex: 25 000 FCFA)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    stock.currentPrice.toFormattedString(),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1B1F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FCFA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Texte de variation : +200 (+0,8 %) aujourd'hui
              Text(
                variationText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: variationColor,
                ),
              ),
              const SizedBox(height: 20),

              // Section Graphique dans une carte blanche aux bords arrondis
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PriceChart(
                      prices: stock.historicalPrices,
                      isGaining: stock.isGaining,
                    ),
                    const SizedBox(height: 16),

                    // Onglets de période : 1M (sélectionné), 6M, 1A
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE8DC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['1M', '6M', '1A'].map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1C1B1F) : const Color(0xFF4A4A4A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Légende en bas de carte
                    const Text(
                      'Historique en construction depuis la mise en service.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section "Ma position" dans une carte blanche
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E2D9), width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ma position',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEBE8E0)),
                    const SizedBox(height: 12),

                    // Quantité
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantité',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        Text(
                          position != null ? '${position.quantity}' : '0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEBE8E0)),
                    const SizedBox(height: 12),

                    // Prix de revient (PRU)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prix de revient (PRU)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        Text(
                          position != null ? formatFCFA(position.pru.round()) : '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEBE8E0)),
                    const SizedBox(height: 12),

                    // Plus-value latente
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Plus-value latente',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        Text(
                          position != null
                              ? '${position.totalGainLoss >= 0 ? '+' : ''}${formatFCFA(position.totalGainLoss.round()).replaceAll(' FCFA', '')} (${position.totalGainLossPercent >= 0 ? '+' : ''}${position.totalGainLossPercent.toStringAsFixed(1).replaceAll('.', ',')} %)'
                              : '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: position != null
                                ? (position.totalGainLoss >= 0 ? const Color(0xFF1F7A4D) : AppColors.loss)
                                : const Color(0xFF1C1B1F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Deux boutons côte à côte : Acheter (vert, plus large) + Vendre (contour blanc/sombre)
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/operation/add?stockCode=${stock.code}&type=achat',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F7A4D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Acheter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(
                          '/operation/add?stockCode=${stock.code}&type=vente',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1C1B1F),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFF1C1B1F), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vendre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1B1F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
