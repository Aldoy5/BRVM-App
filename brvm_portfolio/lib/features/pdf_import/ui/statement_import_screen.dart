import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:brvm_portfolio/core/constants.dart';
import 'package:brvm_portfolio/features/pdf_import/statement_import_provider.dart';

/// Écran permettant d'importer un Relevé de Compte Titres BICI Bourse
/// et de pré-remplir le portefeuille en une seule fois avec détection des titres existants.
class StatementImportScreen extends ConsumerWidget {
  const StatementImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statementImportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Import relevé BICI Bourse'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(statementImportProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    StatementImportState state,
  ) {
    switch (state.status) {
      case StatementImportStatus.idle:
        return _IdleView(
          onPickFile: (bytes, name) =>
              ref.read(statementImportProvider.notifier).parsePdf(bytes, name),
        );

      case StatementImportStatus.parsing:
        return const _LoadingView(message: 'Analyse du relevé en cours…');

      case StatementImportStatus.importing:
        return const _LoadingView(message: 'Enregistrement des positions…');

      case StatementImportStatus.preview:
        return _PreviewView(state: state, ref: ref);

      case StatementImportStatus.success:
        return _SuccessView(
          count: state.importedCount,
          onDone: () {
            ref.read(statementImportProvider.notifier).reset();
            context.pop();
          },
          onImportAnother: () {
            ref.read(statementImportProvider.notifier).reset();
          },
        );

      case StatementImportStatus.error:
        return _ErrorView(
          message: state.errorMessage ?? 'Une erreur est survenue.',
          onRetry: () => ref.read(statementImportProvider.notifier).reset(),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vue initiale : sélection du fichier
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final Future<void> Function(Uint8List bytes, String name) onPickFile;

  const _IdleView({required this.onPickFile});

  Future<void> _pickPdf(BuildContext context) async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (pickedFiles.isEmpty) return;
    final file = pickedFiles.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    await onPickFile(bytes, file.name);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.gainLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gain.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 56,
                  color: AppColors.gain,
                ),
                SizedBox(height: 16),
                Text(
                  'Relevé de Compte Titres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Importez votre relevé BICI Bourse pour renseigner ou synchroniser\n'
                  'vos positions en portefeuille en une seule fois.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Relevé au format PDF numérique (non scanné)',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Détection automatique des titres déjà détenus en portefeuille',
          ),
          const SizedBox(height: 10),
          const _InfoRow(
            icon: Icons.check_circle_outline,
            text: 'Choix de gestion par ligne : Ajuster l\'écart, Remplacer ou Cumuler',
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _pickPdf(context),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Choisir le fichier PDF'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vos données restent strictement locales.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gain),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chargement
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prévisualisation des résultats
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  final StatementImportState state;
  final WidgetRef ref;

  const _PreviewView({required this.state, required this.ref});

  static final _fmtNbr = NumberFormat('#,##0', 'fr_FR');

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final result = state.parseResult!;
    final diffs = state.diffs;
    final selected = state.selectedIndices;
    final notifier = ref.read(statementImportProvider.notifier);
    final allSelected = selected.length == diffs.length;

    return Column(
      children: [
        // En-tête informatif
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 18,
                    color: AppColors.gain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.nomClient ?? 'Relevé BICI Bourse',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (result.dateReleve != null || result.numeroCompte != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (result.dateReleve != null)
                      _MetaChip(
                        label: 'Au ${_fmt(result.dateReleve!)}',
                        icon: Icons.calendar_today_outlined,
                      ),
                    if (result.numeroCompte != null)
                      _MetaChip(
                        label: 'Cpt ${result.numeroCompte}',
                        icon: Icons.account_balance_outlined,
                      ),
                    if (result.soldeEspeces != null)
                      _MetaChip(
                        label: 'Solde SGI : ${_fmtNbr.format(result.soldeEspeces!)} F',
                        icon: Icons.savings_outlined,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Synthèse de comparaison avec le portefeuille
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (state.newCount > 0)
                    _StatusSummaryChip(
                      label: '${state.newCount} nouveau${state.newCount > 1 ? 'x' : ''}',
                      color: AppColors.gain,
                      bgColor: AppColors.gainLight,
                    ),
                  if (state.diffCount > 0)
                    _StatusSummaryChip(
                      label: '${state.diffCount} à ajuster',
                      color: const Color(0xFFE65100),
                      bgColor: const Color(0xFFFFF3E0),
                    ),
                  if (state.matchedCount > 0)
                    _StatusSummaryChip(
                      label: '${state.matchedCount} conforme${state.matchedCount > 1 ? 's' : ''}',
                      color: AppColors.textSecondary,
                      bgColor: AppColors.background,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Avertissements éventuels
        if (result.avertissements.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 16, color: Color(0xFFF57F17)),
                    SizedBox(width: 6),
                    Text(
                      'Avertissements',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final w in result.avertissements)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $w',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Ligne "Tout sélectionner"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${diffs.length} position${diffs.length > 1 ? 's' : ''} sur le relevé',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: notifier.toggleAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste des positions avec diffs
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: diffs.length,
            itemBuilder: (context, index) {
              final diff = diffs[index];
              final isSelected = selected.contains(index);
              return _StatementLineCard(
                diff: diff,
                isSelected: isSelected,
                onToggle: () => notifier.toggleLine(index),
                onModeChanged: (mode) => notifier.setLineMode(index, mode),
              );
            },
          ),
        ),

        // Barre de validation
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selected.length} position${selected.length > 1 ? 's' : ''} sélectionnée${selected.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: selected.isEmpty
                    ? null
                    : () => notifier.importSelected(),
                icon: const Icon(Icons.download_done_outlined),
                label: Text(
                  'Importer ${selected.length} position${selected.length > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusSummaryChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementLineCard extends StatelessWidget {
  final StatementLineDiff diff;
  final bool isSelected;
  final VoidCallback onToggle;
  final ValueChanged<LineImportMode> onModeChanged;

  static final _fmtNbr = NumberFormat('#,##0', 'fr_FR');

  const _StatementLineCard({
    required this.diff,
    required this.isSelected,
    required this.onToggle,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ligne = diff.line;
    final pvLatente = (ligne.cours - ligne.prixRevient) * ligne.quantite;
    final isPvPositive = pvLatente >= 0;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Infos titre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ligne.codeTitre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: AppColors.border, width: 0.6),
                              ),
                              child: Text(
                                '${ligne.quantite} titres',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ligne.libelle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ValueLabel(
                              label: 'PRU',
                              value: '${_fmtNbr.format(ligne.prixRevient)} F',
                            ),
                            const SizedBox(width: 10),
                            _ValueLabel(
                              label: 'Cours',
                              value: '${_fmtNbr.format(ligne.cours)} F',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Plus-value latente
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPvPositive ? '+' : ''}${_fmtNbr.format(pvLatente)} F',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPvPositive ? AppColors.gain : AppColors.loss,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmtNbr.format(ligne.quantite * ligne.cours)} F',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ─── Section Détection et Gestion des positions existantes ──────
              const SizedBox(height: 10),
              if (!diff.existsInPortfolio)
                // Titre nouveau
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gainLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.gain.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, size: 12, color: AppColors.gain),
                        SizedBox(width: 4),
                        Text(
                          'Nouveau titre',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gain,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (diff.isQuantityMatch)
                // Titre déjà conforme
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC5E1A5), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF558B2F)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Déjà en portefeuille : ${diff.existingQuantity} titres (position conforme)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF33691E),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Écart constaté avec le portefeuille existant
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              size: 16, color: Color(0xFFE65100)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'En portefeuille : ${diff.existingQuantity} titres (PRU ${_fmtNbr.format(diff.existingPru)} F)  ➔  '
                              'Écart : ${diff.quantityDiff > 0 ? '+${diff.quantityDiff}' : '${diff.quantityDiff}'} titres',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Sélecteur de stratégie d'import
                      Row(
                        children: [
                          _ModeChoiceChip(
                            label: 'Ajuster (${diff.quantityDiff > 0 ? '+${diff.quantityDiff}' : '${diff.quantityDiff}'})',
                            isSelected: diff.mode == LineImportMode.ajuster,
                            onTap: () => onModeChanged(LineImportMode.ajuster),
                          ),
                          const SizedBox(width: 6),
                          _ModeChoiceChip(
                            label: 'Remplacer (${diff.statementQuantity})',
                            isSelected: diff.mode == LineImportMode.remplacer,
                            onTap: () => onModeChanged(LineImportMode.remplacer),
                          ),
                          const SizedBox(width: 6),
                          _ModeChoiceChip(
                            label: 'Cumuler',
                            isSelected: diff.mode == LineImportMode.cumuler,
                            onTap: () => onModeChanged(LineImportMode.cumuler),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  final String label;
  final String value;

  const _ValueLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: AppColors.textTertiary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Succès
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final int count;
  final VoidCallback onDone;
  final VoidCallback onImportAnother;

  const _SuccessView({
    required this.count,
    required this.onDone,
    required this.onImportAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.gainLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.gain,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Import réussi !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count opération${count > 1 ? 's' : ''} enregistrée${count > 1 ? 's' : ''} '
            'pour mettre à jour votre portefeuille.',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos positions sont désormais synchronisées avec votre relevé.',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onDone,
            child: const Text('Voir le portefeuille'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onImportAnother,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Importer un autre relevé'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Erreur
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.lossLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.loss,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Échec de l\'analyse',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
