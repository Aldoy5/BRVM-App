import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';
import 'package:brvm_portfolio/core/models/operation.dart';
import 'package:brvm_portfolio/core/models/position.dart';
import 'package:brvm_portfolio/data/repositories/operations_repository.dart';
import 'package:brvm_portfolio/features/history/history_providers.dart';
import 'package:brvm_portfolio/features/pdf_import/data/bici_bourse_statement_parser.dart';
import 'package:brvm_portfolio/features/pdf_import/statement_import_provider.dart';

/// Repository mock en mémoire pour tester sans Firebase.
class InMemoryOperationsRepository implements OperationsRepository {
  final List<Operation> operations = [];
  int? sgiBalance;

  @override
  Stream<List<Operation>> watchOperations() => Stream.value(operations);

  @override
  Future<void> saveOperation(Operation operation) async {
    operations.removeWhere((o) => o.id == operation.id);
    operations.add(operation);
  }

  @override
  Future<void> deleteOperation(String operationId) async {
    operations.removeWhere((o) => o.id == operationId);
  }

  @override
  Future<int?> getSgiDeclaredBalance() async => sgiBalance;

  @override
  Future<void> saveSgiDeclaredBalance(int balance) async {
    sgiBalance = balance;
  }
}

void main() {
  group('StatementLineDiff & Détection des titres existants', () {
    test('identifie correctement un nouveau titre', () {
      const line = StatementLine(
        codeTitre: 'SCRC',
        isin: 'CI0000002028',
        libelle: 'SUCRIVOIRE',
        quantite: 10,
        prixRevient: 3000,
        cours: 3200,
      );

      const diff = StatementLineDiff(
        line: line,
        existingPosition: null,
        mode: LineImportMode.nouveau,
      );

      expect(diff.existsInPortfolio, isFalse);
      expect(diff.existingQuantity, equals(0));
      expect(diff.quantityDiff, equals(10));
      expect(diff.isQuantityMatch, isFalse);
    });

    test('identifie un titre existant déjà conforme (quantité identique)', () {
      const line = StatementLine(
        codeTitre: 'SIBC',
        isin: 'CI0000001871',
        libelle: 'SIB',
        quantite: 50,
        prixRevient: 9000,
        cours: 8800,
      );

      const existing = Position(
        stockCode: 'SIBC',
        stockName: 'SIB',
        quantity: 50,
        pru: 9000.0,
        currentPrice: 8800,
        previousClosePrice: 8800,
        dailyVariation: 0.0,
      );

      const diff = StatementLineDiff(
        line: line,
        existingPosition: existing,
        mode: LineImportMode.conforme,
      );

      expect(diff.existsInPortfolio, isTrue);
      expect(diff.existingQuantity, equals(50));
      expect(diff.statementQuantity, equals(50));
      expect(diff.quantityDiff, equals(0));
      expect(diff.isQuantityMatch, isTrue);
    });

    test('calcule correctement l\'écart pour un titre existant (différence positive)', () {
      const line = StatementLine(
        codeTitre: 'BOAC',
        isin: 'CI0000000956',
        libelle: 'BOA CI',
        quantite: 25,
        prixRevient: 12000,
        cours: 11700,
      );

      const existing = Position(
        stockCode: 'BOAC',
        stockName: 'BOA CI',
        quantity: 10,
        pru: 11000.0,
        currentPrice: 11700,
        previousClosePrice: 11700,
        dailyVariation: 0.0,
      );

      const diff = StatementLineDiff(
        line: line,
        existingPosition: existing,
        mode: LineImportMode.ajuster,
      );

      expect(diff.existsInPortfolio, isTrue);
      expect(diff.existingQuantity, equals(10));
      expect(diff.statementQuantity, equals(25));
      expect(diff.quantityDiff, equals(15)); // +15 titres à ajouter
      expect(diff.isQuantityMatch, isFalse);
    });

    test('compte correctement les nouveaux, conformes et à ajuster dans le state', () {
      final diffs = [
        const StatementLineDiff(
          line: StatementLine(
            codeTitre: 'SCRC',
            isin: 'CI0000002028',
            libelle: 'SUCRIVOIRE',
            quantite: 10,
            prixRevient: 3000,
            cours: 3200,
          ),
          existingPosition: null,
          mode: LineImportMode.nouveau,
        ),
        const StatementLineDiff(
          line: StatementLine(
            codeTitre: 'SIBC',
            isin: 'CI0000001871',
            libelle: 'SIB',
            quantite: 50,
            prixRevient: 9000,
            cours: 8800,
          ),
          existingPosition: Position(
            stockCode: 'SIBC',
            stockName: 'SIB',
            quantity: 50,
            pru: 9000.0,
            currentPrice: 8800,
            previousClosePrice: 8800,
            dailyVariation: 0.0,
          ),
          mode: LineImportMode.conforme,
        ),
        const StatementLineDiff(
          line: StatementLine(
            codeTitre: 'BOAC',
            isin: 'CI0000000956',
            libelle: 'BOA CI',
            quantite: 25,
            prixRevient: 12000,
            cours: 11700,
          ),
          existingPosition: Position(
            stockCode: 'BOAC',
            stockName: 'BOA CI',
            quantity: 10,
            pru: 11000.0,
            currentPrice: 11700,
            previousClosePrice: 11700,
            dailyVariation: 0.0,
          ),
          mode: LineImportMode.ajuster,
        ),
      ];

      final state = StatementImportState(diffs: diffs);
      expect(state.newCount, equals(1));
      expect(state.matchedCount, equals(1));
      expect(state.diffCount, equals(1));
    });

    test('importSelected exécute l\'ajustement d\'écart sans doublon', () async {
      final mockRepo = InMemoryOperationsRepository();
      final container = ProviderContainer(
        overrides: [
          operationsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(statementImportProvider.notifier);

      final diffs = [
        const StatementLineDiff(
          line: StatementLine(
            codeTitre: 'BOAC',
            isin: 'CI0000000956',
            libelle: 'BOA CI',
            quantite: 25,
            prixRevient: 12000,
            cours: 11700,
          ),
          existingPosition: Position(
            stockCode: 'BOAC',
            stockName: 'BOA CI',
            quantity: 10,
            pru: 11000.0,
            currentPrice: 11700,
            previousClosePrice: 11700,
            dailyVariation: 0.0,
          ),
          mode: LineImportMode.ajuster,
        ),
      ];

      notifier.state = StatementImportState(
        status: StatementImportStatus.preview,
        parseResult: StatementParseResult(
          numeroCompte: '902501001',
          dateReleve: DateTime(2026, 11, 1),
          soldeEspeces: 15000,
          lignes: [diffs[0].line],
        ),
        diffs: diffs,
        selectedIndices: {0},
      );

      await notifier.importSelected();

      expect(notifier.state.status, equals(StatementImportStatus.success));
      expect(notifier.state.importedCount, equals(1));

      // L'opération créée doit être de 15 titres (écart 25 - 10) et non 25 !
      final ops = container.read(operationsProvider);
      expect(ops.length, equals(1));
      expect(ops.first.type, equals(OperationType.achat));
      expect(ops.first.stockCode, equals('BOAC'));
      expect(ops.first.quantity, equals(15));
      expect(ops.first.notes, contains('Ajustement de solde (+15 titres)'));
    });
  });
}
