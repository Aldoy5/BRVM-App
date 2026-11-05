import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../history/history_providers.dart';
import 'data/bici_bourse_statement_parser.dart';

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
  final String? errorMessage;

  /// Lignes sélectionnées par l'utilisateur pour import (par défaut toutes).
  final Set<int> selectedIndices;

  /// Nombre d'opérations effectivement créées lors du dernier import.
  final int importedCount;

  const StatementImportState({
    this.status = StatementImportStatus.idle,
    this.parseResult,
    this.errorMessage,
    this.selectedIndices = const {},
    this.importedCount = 0,
  });

  StatementImportState copyWith({
    StatementImportStatus? status,
    StatementParseResult? parseResult,
    String? errorMessage,
    Set<int>? selectedIndices,
    int? importedCount,
  }) {
    return StatementImportState(
      status: status ?? this.status,
      parseResult: parseResult ?? this.parseResult,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      importedCount: importedCount ?? this.importedCount,
    );
  }
}

/// Notifier gérant le flux complet d'import d'un relevé de compte BICI Bourse.
class StatementImportNotifier extends Notifier<StatementImportState> {
  @override
  StatementImportState build() => const StatementImportState();

  /// Analyse le PDF fourni sous forme de bytes.
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

      // Par défaut, toutes les lignes sont sélectionnées
      final allIndices = {for (int i = 0; i < result.lignes.length; i++) i};

      state = StatementImportState(
        status: StatementImportStatus.preview,
        parseResult: result,
        selectedIndices: allIndices,
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

  /// Sélectionne ou désélectionne toutes les lignes.
  void toggleAll() {
    final total = state.parseResult?.lignes.length ?? 0;
    if (state.selectedIndices.length == total) {
      state = state.copyWith(selectedIndices: {});
    } else {
      state = state.copyWith(
        selectedIndices: {for (int i = 0; i < total; i++) i},
      );
    }
  }

  /// Importe les lignes sélectionnées comme opérations d'achat.
  Future<void> importSelected() async {
    final result = state.parseResult;
    if (result == null || state.selectedIndices.isEmpty) return;

    state = state.copyWith(status: StatementImportStatus.importing);

    try {
      final notifier = ref.read(operationsProvider.notifier);
      final dateReleve = result.dateReleve ?? DateTime.now();
      int count = 0;

      // On trie par index pour respecter l'ordre du relevé
      final sorted = state.selectedIndices.toList()..sort();

      for (final idx in sorted) {
        if (idx >= result.lignes.length) continue;
        final ligne = result.lignes[idx];
        final op = ligne.toOperation(
          dateReleve: dateReleve,
          notes: 'Importé depuis relevé BICI Bourse'
              '${result.dateReleve != null ? ' du ${_fmt(result.dateReleve!)}' : ''}'
              '${result.numeroCompte != null ? ' — Cpt ${result.numeroCompte}' : ''}',
        );
        await notifier.addOperation(op);
        count++;
      }

      // Met � jour le solde esp�ces SGI d�clar� si pr�sent sur le relev�
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
