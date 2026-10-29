import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../../../core/models/portfolio_summary.dart';
import '../../auth/auth_providers.dart';
import '../../history/history_providers.dart';

/// En-tête et synthèse financière du portefeuille selon le mockup épuré
class PortfolioSummaryCard extends ConsumerWidget {
  final PortfolioSummary summary;

  const PortfolioSummaryCard({
    super.key,
    required this.summary,
  });

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter de votre compte ?'),
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
              await ref.read(authRepositoryProvider).signOut();
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showReconcileDialog(BuildContext context, WidgetRef ref) {
    final currentBalance = ref.read(sgiDeclaredBalanceProvider);
    final controller = TextEditingController(
      text: currentBalance > 0 ? currentBalance.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Rapprochement Solde SGI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indiquez le solde espèces disponible figurant sur votre compte SGI :',
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
    final dateStr = DateFormat('dd/MM/yyyy').format(summary.marketDate);
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne du haut : Date du cours + Badge utilisateur connecté avec déconnexion
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Portefeuille · cours du $dateStr',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (user != null)
              InkWell(
                onTap: () => _confirmSignOut(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          user.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.logout,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Label 'Valorisation totale'
        const Text(
          'Valorisation totale',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),

        // Grand chiffre héroïque en gras : '4 820 000 FCFA'
        Text(
          formatFCFA(summary.totalValuation),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),

        // Deux bannières/pills vertes pour les gains
        _buildGainPill(
          label: "Aujourd'hui",
          amount: summary.dailyGainLoss,
          percent: summary.dailyGainLossPercent,
        ),
        const SizedBox(height: 8),
        _buildGainPill(
          label: "Depuis l'investissement",
          amount: summary.totalGainLoss,
          percent: summary.totalGainLossPercent,
        ),
        const SizedBox(height: 14),

        // Carte blanche : 'Solde disponible' + '310 000 FCFA' + bouton 'Rapprocher'
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solde disponible',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatFCFA(summary.cashBalance),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: const BorderSide(color: AppColors.textPrimary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showReconcileDialog(context, ref),
                child: const Text(
                  'Rapprocher',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGainPill({
    required String label,
    required int amount,
    required double percent,
  }) {
    final isLoss = amount < 0;
    final isNeutral = amount == 0;

    final Color bgColor = isNeutral
        ? AppColors.neutralLight
        : (isLoss ? const Color(0xFFFFEBEE) : const Color(0xFFE2EFE7));
    final Color textColor = isNeutral
        ? AppColors.neutral
        : (isLoss ? const Color(0xFFD32F2F) : const Color(0xFF1F6B47));

    final sign = amount > 0 ? '+' : (amount < 0 ? '-' : '');
    final amtStr = '$sign${AppFormatters.formatInteger(amount.abs())}';

    final pctSign = percent > 0 ? '+' : (percent < 0 ? '-' : '');
    final pctValue = NumberFormat('0.##', 'fr_FR').format(percent.abs());
    final pctStr = '$pctSign$pctValue %';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $amtStr ($pctStr)',
        style: TextStyle(
          color: textColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
