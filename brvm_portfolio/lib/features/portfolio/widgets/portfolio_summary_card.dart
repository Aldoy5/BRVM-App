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
import '../portfolio_display_mode.dart';

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

  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Comprendre les chiffres',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                title: '💼 Valorisation totale',
                content:
                    'Valeur de l\'ensemble de vos actions au cours actuel du marché (Quantité × Cours).',
              ),
              const Divider(height: 20),
              _buildHelpSection(
                title: '📈 Mode « Depuis l\'achat »',
                content:
                    '• PRU (Prix de Revient Unitaire) : Coût moyen d\'achat par action, frais de courtage SGI et taxes inclus.\n'
                    '• Plus/Moins-value latente : Gain ou perte théorique calculé par rapport à votre PRU : Quantité × (Cours - PRU).',
              ),
              const Divider(height: 20),
              _buildHelpSection(
                title: '⚡ Mode « Aujourd\'hui »',
                content:
                    '• Gain / Perte du jour : Variation financière sur la séance actuelle par rapport au cours de clôture de la veille : Quantité × (Cours - Cours Veille).',
              ),
              const Divider(height: 20),
              _buildHelpSection(
                title: '⏪ Mode « Hier (Veille) »',
                content:
                    '• Gain réalisé la veille : Résultat net obtenu lors de la journée d\'hier par rapport à l\'avant-veille : Quantité × (Cours Veille - Cours Avant-veille).\n'
                    '• Valorisation de la veille : Montant total de votre portefeuille à la clôture de la veille.',
              ),
              const Divider(height: 20),
              _buildHelpSection(
                title: '📊 Barre de progression & Couleur',
                content:
                    '• Pourcentage : Poids du titre dans votre portefeuille d\'actions.\n'
                    '• Couleur verte : Titre en gain.\n'
                    '• Couleur rouge : Titre en perte.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('J\'ai compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
    final displayMode = ref.watch(portfolioDisplayModeProvider);

    // Détermination des libellés et montants selon le mode
    final String pillLabel;
    final String pillSubtitle;
    final int pillAmount;
    final double pillPercent;

    switch (displayMode) {
      case PortfolioDisplayMode.total:
        pillLabel = "Plus-value totale (vs PRU)";
        pillSubtitle = "Plus-value latente calculée par rapport au coût de revient (PRU)";
        pillAmount = summary.totalGainLoss;
        pillPercent = summary.totalGainLossPercent;
        break;
      case PortfolioDisplayMode.session:
        pillLabel = "Gain du jour (vs veille)";
        pillSubtitle =
            "Séance en direct par rapport à la clôture veille (${formatFCFA(summary.yesterdayValuation)})";
        pillAmount = summary.dailyGainLoss;
        pillPercent = summary.dailyGainLossPercent;
        break;
      case PortfolioDisplayMode.yesterday:
        pillLabel = "Gagné la veille (Hier)";
        pillSubtitle =
            "Clôture d'hier : ${formatFCFA(summary.yesterdayValuation)} (gain vs avant-veille)";
        pillAmount = summary.yesterdayGainLoss;
        pillPercent = summary.yesterdayGainLossPercent;
        break;
    }

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

        // Label 'Valorisation totale' avec bouton d'aide explicative
        Row(
          children: [
            const Text(
              'Valorisation totale',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showExplanationDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
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

        // Commutateur à 3 boutons : [ Depuis l'achat | Aujourd'hui | Hier ]
        _buildDisplayModeToggle(ref),
        const SizedBox(height: 10),

        // Pill de performance dynamique selon le mode sélectionné
        _buildGainPill(
          label: pillLabel,
          subtitle: pillSubtitle,
          amount: pillAmount,
          percent: pillPercent,
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

  /// Construit le commutateur à 3 positions : « Depuis l'achat », « Aujourd'hui », « Hier (Veille) ».
  Widget _buildDisplayModeToggle(WidgetRef ref) {
    final mode = ref.watch(portfolioDisplayModeProvider);
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            ref: ref,
            label: "Depuis l'achat",
            icon: Icons.trending_up,
            mode: PortfolioDisplayMode.total,
            isSelected: mode == PortfolioDisplayMode.total,
          ),
          _buildToggleButton(
            ref: ref,
            label: "Aujourd'hui",
            icon: Icons.today,
            mode: PortfolioDisplayMode.session,
            isSelected: mode == PortfolioDisplayMode.session,
          ),
          _buildToggleButton(
            ref: ref,
            label: "Hier (Veille)",
            icon: Icons.history,
            mode: PortfolioDisplayMode.yesterday,
            isSelected: mode == PortfolioDisplayMode.yesterday,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required PortfolioDisplayMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(portfolioDisplayModeProvider.notifier).setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGainPill({
    required String label,
    required String subtitle,
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
    final amtStr = '$sign${AppFormatters.formatInteger(amount.abs())} FCFA';

    final pctSign = percent > 0 ? '+' : (percent < 0 ? '-' : '');
    final pctValue = NumberFormat('0.00', 'fr_FR').format(percent.abs());
    final pctStr = '$pctSign$pctValue %';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$amtStr ($pctStr)',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
