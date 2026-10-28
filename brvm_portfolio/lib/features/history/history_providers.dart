import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/operation.dart';

/// Filtre des opérations pour l'historique
enum HistoryFilter {
  all('Toutes'),
  purchases('Achats'),
  sales('Ventes'),
  cash('Dépôts & Retraits');

  final String label;
  const HistoryFilter(this.label);
}

/// Liste initiale d'opérations d'exemple réalistes
final List<Operation> kInitialOperations = [
  Operation(
    id: 'op-001',
    type: OperationType.depot,
    cashAmount: 15000000,
    fees: 0,
    date: DateTime(2026, 9, 1, 10, 0),
    notes: 'Virement initial vers compte SGI',
  ),
  Operation(
    id: 'op-002',
    type: OperationType.achat,
    stockCode: 'SNTS',
    stockName: 'Sonatel Sénégal',
    quantity: 250,
    unitPrice: 18200,
    fees: 53690, // ~1.18%
    date: DateTime(2026, 9, 5, 11, 15),
    notes: 'Achat carnet principal',
  ),
  Operation(
    id: 'op-003',
    type: OperationType.achat,
    stockCode: 'SGBC',
    stockName: 'Société Générale Côte d\'Ivoire',
    quantity: 150,
    unitPrice: 16500,
    fees: 29205,
    date: DateTime(2026, 9, 12, 14, 20),
    notes: 'Renforcement secteur bancaire',
  ),
  Operation(
    id: 'op-004',
    type: OperationType.achat,
    stockCode: 'PALC',
    stockName: 'Palmci Côte d\'Ivoire',
    quantity: 300,
    unitPrice: 6800,
    fees: 24072,
    date: DateTime(2026, 9, 20, 10, 45),
    notes: 'Position agro-industrie',
  ),
  Operation(
    id: 'op-005',
    type: OperationType.achat,
    stockCode: 'ECOC',
    stockName: 'Ecobank Côte d\'Ivoire',
    quantity: 400,
    unitPrice: 7100,
    fees: 33512,
    date: DateTime(2026, 10, 2, 13, 0),
    notes: 'Achat pour dividende',
  ),
  Operation(
    id: 'op-006',
    type: OperationType.achat,
    stockCode: 'TTLC',
    stockName: 'TotalEnergies Marketing CI',
    quantity: 500,
    unitPrice: 2250,
    fees: 13275,
    date: DateTime(2026, 10, 10, 9, 30),
    notes: 'Rendement défensif',
  ),
  Operation(
    id: 'op-007',
    type: OperationType.achat,
    stockCode: 'SIBC',
    stockName: 'Société Ivoirienne de Banque',
    quantity: 200,
    unitPrice: 5900,
    fees: 13924,
    date: DateTime(2026, 10, 18, 11, 0),
    notes: 'Renforcement bancaire',
  ),
  Operation(
    id: 'op-008',
    type: OperationType.vente,
    stockCode: 'PALC',
    stockName: 'Palmci Côte d\'Ivoire',
    quantity: 50,
    unitPrice: 7400,
    fees: 4366,
    date: DateTime(2026, 10, 22, 14, 10),
    notes: 'Prise de bénéfice partielle',
  ),
];

/// Notifier pour la liste des opérations
class OperationsNotifier extends Notifier<List<Operation>> {
  @override
  List<Operation> build() {
    return kInitialOperations;
  }

  void addOperation(Operation operation) {
    state = [operation, ...state];
  }

  void updateOperation(Operation updated) {
    state = [
      for (final op in state)
        if (op.id == updated.id) updated else op,
    ];
  }

  void deleteOperation(String id) {
    state = state.where((op) => op.id != id).toList();
  }
}

final operationsProvider =
    NotifierProvider<OperationsNotifier, List<Operation>>(OperationsNotifier.new);

/// Notifier pour le filtre de l'historique
class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void selectFilter(HistoryFilter filter) {
    state = filter;
  }
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(HistoryFilterNotifier.new);

/// Liste des opérations filtrées et triées par date la plus récente
final filteredOperationsProvider = Provider<List<Operation>>((ref) {
  final operations = ref.watch(operationsProvider);
  final filter = ref.watch(historyFilterProvider);

  final list = operations.where((op) {
    switch (filter) {
      case HistoryFilter.all:
        return true;
      case HistoryFilter.purchases:
        return op.type == OperationType.achat;
      case HistoryFilter.sales:
        return op.type == OperationType.vente;
      case HistoryFilter.cash:
        return op.type.isCashOperation;
    }
  }).toList();

  // Tri par date décroissante (plus récentes en premier)
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});

/// Provider pour récupérer une opération spécifique par son ID
final operationByIdProvider = Provider.family<Operation?, String>((ref, id) {
  final operations = ref.watch(operationsProvider);
  try {
    return operations.firstWhere((op) => op.id == id);
  } catch (_) {
    return null;
  }
});

/// Notifier pour le solde espèces réel déclaré sur le relevé SGI par l'utilisateur
class SgiDeclaredBalanceNotifier extends Notifier<int> {
  @override
  int build() {
    // Solde SGI initial réaliste (ex: 1 850 000 FCFA)
    return 1850000;
  }

  void updateBalance(int newBalance) {
    state = newBalance;
  }
}

final sgiDeclaredBalanceProvider =
    NotifierProvider<SgiDeclaredBalanceNotifier, int>(SgiDeclaredBalanceNotifier.new);

/// Modèle pour le rapprochement bancaire / SGI
class ReconciliationData {
  final int sgiDeclaredBalance; // Mon solde SGI
  final int appCalculatedBalance; // L'app dit
  final int difference; // Écart (sgiDeclaredBalance - appCalculatedBalance)

  const ReconciliationData({
    required this.sgiDeclaredBalance,
    required this.appCalculatedBalance,
    required this.difference,
  });

  bool get isReconciled => difference == 0;
  bool get hasSurplus => difference > 0;
  bool get hasDeficit => difference < 0;
}

/// Provider de calcul du rapprochement SGI vs App
final reconciliationProvider = Provider<ReconciliationData>((ref) {
  final operations = ref.watch(operationsProvider);
  final sgiDeclared = ref.watch(sgiDeclaredBalanceProvider);

  // Calcul du solde de trésorerie net d'après toutes les opérations enregistrées
  int calculatedBalance = 0;
  for (final op in operations) {
    calculatedBalance += op.cashImpact;
  }

  return ReconciliationData(
    sgiDeclaredBalance: sgiDeclared,
    appCalculatedBalance: calculatedBalance,
    difference: sgiDeclared - calculatedBalance,
  );
});
