import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/operation.dart';
import '../../core/models/position.dart';
import '../history/history_providers.dart';
import '../portfolio/portfolio_providers.dart';
import 'data/bici_bourse_statement_parser.dart';

/// Mode d'import pour une ligne donnée du relevé.
enum LineImportMode {
  /// Nouveau titre : création directe de la position (aucun titre en portefeuille).
  nouveau('Nouveau'),

  /// Déjà conforme : quantité identique dans le portefeuille.
  conforme('Conforme'),

  /// Ajuster l'écart : n'ajouter ou ne retrancher que la différence de quantité.
  ajuster('Ajuster l\'écart'),

  /// Remplacer : solde la position antérieure et réaligne sur le relevé.
  remplacer('Remplacer'),

  /// Cumuler : ajoute la totalité sans tenir compte de la position existante.
  cumuler('Cumuler');

  final String label;
  const LineImportMode(this.label);
}

/// Comparaison entre une ligne du relevé et une éventuelle position existante en portefeuille.
class StatementLineDiff {
  final StatementLine line;
  final Position? existingPosition;
  final LineImportMode mode;

  const StatementLineDiff({
    required this.line,
    this.existingPosition,
    required this.mode,
  });

  bool get existsInPortfolio =>
      existingPosition != null && existingPosition!.quantity > 0;

  int get existingQuantity => existingPosition?.quantity ?? 0;
  int get existingPru => existingPosition?.pru.round() ?? 0;
  int get statementQuantity => line.quantite;
  int get statementPru => line.prixRevient;

  /// Différence de quantité : (relevé - existant).
  /// Positif = titres supplémentaires à ajouter.
  /// Négatif = titres en trop à déduire.
  int get quantityDiff => statementQuantity - existingQuantity;

  /// Indique si la quantité en portefeuille est strictement égale à celle du relevé.
  bool get isQuantityMatch => existsInPortfolio && quantityDiff == 0;

  StatementLineDiff copyWith({
    StatementLine? line,
    Position? existingPosition,
    LineImportMode? mode,
  }) {
    return StatementLineDiff(
      line: line ?? this.line,
      existingPosition: existingPosition ?? this.existingPosition,
      mode: mode ?? this.mode,
    );
  }
}

/// État de l'import du relevé de compte.
enum StatementImportStatus {
  idle,
  parsing,
  preview,
  importing,
  success,
  error,
}

/// État complet du flux d'import du relevé.
class StatementImportState {
  final StatementImportStatus status;
  final StatementParseResult? parseResult;
  final List<StatementLineDiff> diffs;
  final String? errorMessage;

  /// Lignes sélectionnées par l'utilisateur pour import.
  final Set<int> selectedIndices;

  /// Nombre d'opérations effectivement créées lors du dernier import.
  final int importedCount;

  const StatementImportState({
    this.status = StatementImportStatus.idle,
    this.parseResult,
    this.diffs = const [],
    this.errorMessage,
    this.selectedIndices = const {},
    this.importedCount = 0,
  });

  int get newCount =>
      diffs.where((d) => !d.existsInPortfolio).length;

  int get matchedCount =>
      diffs.where((d) => d.isQuantityMatch).length;

  int get diffCount =>
      diffs.where((d) => d.existsInPortfolio && !d.isQuantityMatch).length;

  StatementImportState copyWith({
    StatementImportStatus? status,
    StatementParseResult? parseResult,
    List<StatementLineDiff>? diffs,
    String? errorMessage,
    Set<int>? selectedIndices,
    int? importedCount,
  }) {
    return StatementImportState(
      status: status ?? this.status,
      parseResult: parseResult ?? this.parseResult,
      diffs: diffs ?? this.diffs,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      importedCount: importedCount ?? this.importedCount,
    );
  }
}

/// Notifier gérant le flux complet d'import d'un relevé de compte BICI Bourse
/// avec détection intelligente des positions préexistantes.
class StatementImportNotifier extends Notifier<StatementImportState> {
  @override
  StatementImportState build() => const StatementImportState();

  /// Analyse le PDF fourni sous forme de bytes et compare avec le portefeuille existant.
  Future<void> parsePdf(Uint8List bytes, String fileName) async {
    state = const StatementImportState(status: StatementImportStatus.parsing);

    try {
      final result = await BiciBourseStatementParser.parse(bytes);

      if (result.erreurBloquante != null) {
        state = StatementImportState(
          status: StatementImportStatus.error,
          errorMessage: result.erreurBloquante,
        );
        return;
      }

      // 1. Récupération des positions réelles actuellement détenues en portefeuille
      final currentPositions = ref.read(portfolioPositionsProvider);
      final positionMap = {
        for (final p in currentPositions) p.stockCode.toUpperCase(): p
      };

      // 2. Construction des diffs pour chaque ligne
      final diffs = <StatementLineDiff>[];
      final selectedIndices = <int>{};

      for (int i = 0; i < result.lignes.length; i++) {
        final ligne = result.lignes[i];
        final existing = positionMap[ligne.codeTitre.toUpperCase()];

        final LineImportMode initialMode;
        if (existing == null || existing.quantity == 0) {
          initialMode = LineImportMode.nouveau;
          selectedIndices.add(i); // Sélectionné par défaut
        } else if (existing.quantity == ligne.quantite) {
          initialMode = LineImportMode.conforme;
          // Décoché par défaut car la position est déjà conforme !
        } else {
          initialMode = LineImportMode.ajuster;
          selectedIndices.add(i); // Sélectionné par défaut pour régulariser l'écart
        }

        diffs.add(StatementLineDiff(
          line: ligne,
          existingPosition: existing,
          mode: initialMode,
        ));
      }

      state = StatementImportState(
        status: StatementImportStatus.preview,
        parseResult: result,
        diffs: diffs,
        selectedIndices: selectedIndices,
      );
    } catch (e) {
      state = StatementImportState(
        status: StatementImportStatus.error,
        errorMessage: 'Erreur inattendue lors de l\'analyse : $e',
      );
    }
  }

  /// Bascule la sélection d'une ligne.
  void toggleLine(int index) {
    final current = Set<int>.from(state.selectedIndices);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    state = state.copyWith(selectedIndices: current);
  }

  /// Change le mode de traitement d'une ligne et s'assure qu'elle est cochée.
  void setLineMode(int index, LineImportMode mode) {
    if (index >= state.diffs.length) return;
    final updatedDiffs = List<StatementLineDiff>.from(state.diffs);
    updatedDiffs[index] = updatedDiffs[index].copyWith(mode: mode);

    final currentSelected = Set<int>.from(state.selectedIndices);
    if (mode == LineImportMode.conforme) {
      currentSelected.remove(index);
    } else {
      currentSelected.add(index);
    }

    state = state.copyWith(
      diffs: updatedDiffs,
      selectedIndices: currentSelected,
    );
  }

  /// Sélectionne ou désélectionne toutes les lignes.
  void toggleAll() {
    final total = state.diffs.length;
    if (state.selectedIndices.length == total) {
      state = state.copyWith(selectedIndices: {});
    } else {
      state = state.copyWith(
        selectedIndices: {for (int i = 0; i < total; i++) i},
      );
    }
  }

  /// Importe les lignes sélectionnées selon leur mode de traitement respectif.
  Future<void> importSelected() async {
    final result = state.parseResult;
    if (result == null || state.selectedIndices.isEmpty) return;

    state = state.copyWith(status: StatementImportStatus.importing);

    try {
      final notifier = ref.read(operationsProvider.notifier);
      final dateReleve = result.dateReleve ?? DateTime.now();
      int count = 0;

      final sorted = state.selectedIndices.toList()..sort();

      for (final idx in sorted) {
        if (idx >= state.diffs.length) continue;
        final diff = state.diffs[idx];
        final ligne = diff.line;
        final timestamp = dateReleve.millisecondsSinceEpoch + idx;

        switch (diff.mode) {
          case LineImportMode.nouveau:
          case LineImportMode.cumuler:
            // Achat pur de la totalité du relevé
            final op = Operation(
              id: 'import_${ligne.codeTitre}_$timestamp',
              type: OperationType.achat,
              date: ligne.dateCours ?? dateReleve,
              stockCode: ligne.codeTitre,
              stockName: ligne.libelle,
              quantity: ligne.quantite,
              unitPrice: ligne.prixRevient,
              fees: 0,
              notes: diff.mode == LineImportMode.cumuler
                  ? 'Ajout cumulé (${ligne.quantite} titres) depuis relevé BICI Bourse'
                  : 'Import relevé BICI Bourse ${_fmt(dateReleve)}',
            );
            await notifier.addOperation(op);
            count++;
            break;

          case LineImportMode.ajuster:
            if (diff.quantityDiff > 0) {
              // Titres à ajouter : on calcule le prix d'achat d'ajustement
              // pour que le PRU final coïncide au plus près avec celui du relevé.
              final targetTotalCost = diff.statementQuantity * diff.statementPru;
              final currentTotalCost = diff.existingQuantity * diff.existingPru;
              final costDiff = targetTotalCost - currentTotalCost;
              final adjPrice = (costDiff > 0 && diff.quantityDiff > 0)
                  ? (costDiff ~/ diff.quantityDiff)
                  : ligne.prixRevient;

              final op = Operation(
                id: 'ajust_${ligne.codeTitre}_$timestamp',
                type: OperationType.achat,
                date: ligne.dateCours ?? dateReleve,
                stockCode: ligne.codeTitre,
                stockName: ligne.libelle,
                quantity: diff.quantityDiff,
                unitPrice: adjPrice,
                fees: 0,
                notes: 'Ajustement de solde (+${diff.quantityDiff} titres) '
                    'depuis relevé BICI Bourse (actuel: ${diff.existingQuantity} ➔ cible: ${diff.statementQuantity})',
              );
              await notifier.addOperation(op);
              count++;
            } else if (diff.quantityDiff < 0) {
              // Titres en trop en portefeuille : vente d'ajustement
              final qteVente = -diff.quantityDiff;
              final op = Operation(
                id: 'ajust_${ligne.codeTitre}_$timestamp',
                type: OperationType.vente,
                date: ligne.dateCours ?? dateReleve,
                stockCode: ligne.codeTitre,
                stockName: ligne.libelle,
                quantity: qteVente,
                unitPrice: ligne.cours,
                fees: 0,
                notes: 'Ajustement de solde (-$qteVente titres) '
                    'depuis relevé BICI Bourse (actuel: ${diff.existingQuantity} ➔ cible: ${diff.statementQuantity})',
              );
              await notifier.addOperation(op);
              count++;
            }
            break;

          case LineImportMode.remplacer:
            // 1. Si position existante : on solde l'ancienne ligne
            if (diff.existingQuantity > 0) {
              final closeOp = Operation(
                id: 'cloture_${ligne.codeTitre}_$timestamp',
                type: OperationType.vente,
                date: dateReleve.subtract(const Duration(minutes: 1)),
                stockCode: ligne.codeTitre,
                stockName: ligne.libelle,
                quantity: diff.existingQuantity,
                unitPrice: diff.existingPru,
                fees: 0,
                notes: 'Clôture comptable avant réalignement sur relevé BICI Bourse',
              );
              await notifier.addOperation(closeOp);
            }

            // 2. On recrée la position exacte du relevé
            final newOp = Operation(
              id: 'realign_${ligne.codeTitre}_$timestamp',
              type: OperationType.achat,
              date: ligne.dateCours ?? dateReleve,
              stockCode: ligne.codeTitre,
              stockName: ligne.libelle,
              quantity: ligne.quantite,
              unitPrice: ligne.prixRevient,
              fees: 0,
              notes: 'Réalignement officiel sur relevé BICI Bourse du ${_fmt(dateReleve)}',
            );
            await notifier.addOperation(newOp);
            count++;
            break;

          case LineImportMode.conforme:
            // Position déjà conforme, aucune opération requise
            break;
        }
      }

      // Met à jour le solde espèces SGI déclaré si présent sur le relevé
      if (result.soldeEspeces != null) {
        await ref
            .read(sgiDeclaredBalanceProvider.notifier)
            .updateBalance(result.soldeEspeces!);
      }

      state = state.copyWith(
        status: StatementImportStatus.success,
        importedCount: count,
      );
    } catch (e) {
      state = state.copyWith(
        status: StatementImportStatus.error,
        errorMessage: 'Erreur lors de l\'enregistrement des opérations : $e',
      );
    }
  }

  /// Réinitialise pour permettre un nouvel import.
  void reset() {
    state = const StatementImportState();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

final statementImportProvider =
    NotifierProvider<StatementImportNotifier, StatementImportState>(
  StatementImportNotifier.new,
);
