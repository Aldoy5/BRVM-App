import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/extensions.dart';
import '../../../core/formatters.dart';
import '../../../core/models/operation.dart';
import '../history_providers.dart';

/// Carte de rapprochement bancaire / SGI
/// Permet de confronter le solde réel de l'avis de la SGI avec le solde calculé par l'application
class ReconciliationCard extends ConsumerStatefulWidget {
  const ReconciliationCard({super.key});

  @override
  ConsumerState<ReconciliationCard> createState() => _ReconciliationCardState();
}

class _ReconciliationCardState extends ConsumerState<ReconciliationCard> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final currentBalance = ref.read(sgiDeclaredBalanceProvider);
    _controller = TextEditingController(
      text: currentBalance > 0 ? AppFormatters.formatInteger(currentBalance) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reconciliation = ref.watch(reconciliationProvider);
    final diff = reconciliation.difference;

    // Synchronisation du champ de saisie si la valeur change hors focus utilisateur
    ref.listen<int>(sgiDeclaredBalanceProvider, (prev, next) {
      if (!_isFocused) {
        final currentTextValue =
            int.tryParse(_controller.text.replaceAll(RegExp(r'\s+'), ''));
        if (currentTextValue != next) {
          _controller.text = AppFormatters.formatInteger(next);
        }
      }
    });

    final String ecartText;
    final Color ecartColor;

    if (diff > 0) {
      ecartText = '+${formatFCFA(diff)}';
      ecartColor = AppColors.loss; // Rouge pour un écart positif conformément à la maquette
    } else if (diff < 0) {
      ecartText = '-${formatFCFA(diff.abs())}';
      ecartColor = AppColors.loss;
    } else {
      ecartText = '0 FCFA';
      ecartColor = AppColors.gain;
    }

    final String buttonDiffText = diff > 0
        ? '+${AppFormatters.formatInteger(diff)}'
        : (diff < 0 ? '-${AppFormatters.formatInteger(diff.abs())}' : '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la carte
            const Text(
              'Rapprochement avec la SGI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Libellé du champ de saisie
            const Text(
              'Solde affiché par ma SGI (FCFA)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            // Champ de saisie éditable du solde SGI
            Focus(
              onFocusChange: (hasFocus) {
                _isFocused = hasFocus;
                if (!hasFocus) {
                  final val = int.tryParse(
                    _controller.text.replaceAll(RegExp(r'\s+'), ''),
                  );
                  if (val != null) {
                    _controller.text = AppFormatters.formatInteger(val);
                  }
                }
              },
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                ],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '312 500',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (text) {
                  final raw = text.replaceAll(RegExp(r'\s+'), '');
                  final val = int.tryParse(raw);
                  if (val != null) {
                    ref.read(sgiDeclaredBalanceProvider.notifier).updateBalance(val);
                  }
                },
              ),
            ),
            const SizedBox(height: 14),

            // Ligne : Solde de l'app
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Solde de l'app",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatFCFA(reconciliation.appCalculatedBalance),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ligne : Écart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Écart',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  ecartText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ecartColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bouton vert d'ajustement
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceVariant,
                  disabledForegroundColor: AppColors.textTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: diff == 0
                    ? null
                    : () {
                        final isCredit = diff > 0;
                        final op = Operation(
                          id: 'op-${DateTime.now().millisecondsSinceEpoch}',
                          type: isCredit ? OperationType.depot : OperationType.retrait,
                          cashAmount: diff.abs(),
                          fees: 0,
                          date: DateTime.now(),
                          notes: 'écart SGI',
                        );
                        ref.read(operationsProvider.notifier).addOperation(op);
                        context.showAppSnackBar(
                          'Ajustement de $buttonDiffText FCFA enregistré',
                          isSuccess: true,
                        );
                      },
                child: Text(
                  diff == 0
                      ? 'Aucun ajustement nécessaire'
                      : 'Créer un ajustement de $buttonDiffText',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
