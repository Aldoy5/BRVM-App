import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Aucune donnée fictive : la liste démarre vide et stocke uniquement les opérations réelles de l'utilisateur
const List<Operation> kInitialOperations = [];

/// Notifier pour la liste des opérations réelles avec persistance locale
class OperationsNotifier extends Notifier<List<Operation>> {
  static const _storageKey = 'user_real_operations_v1';

  @override
  List<Operation> build() {
    _loadFromStorage();
    return kInitialOperations;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        state = list
            .map((item) => Operation.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[OperationsNotifier] Erreur de chargement local : $e');
    }
  }

  Future<void> _saveToStorage(List<Operation> ops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(ops.map((op) => op.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[OperationsNotifier] Erreur d\'enregistrement local : $e');
    }
  }

  void addOperation(Operation operation) {
    state = [operation, ...state];
    _saveToStorage(state);
  }

  void updateOperation(Operation updated) {
    state = [
      for (final op in state)
        if (op.id == updated.id) updated else op,
    ];
    _saveToStorage(state);
  }

  void deleteOperation(String id) {
    state = state.where((op) => op.id != id).toList();
    _saveToStorage(state);
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
  static const _storageKey = 'user_sgi_balance_v1';

  @override
  int build() {
    _loadFromStorage();
    // Valeur initiale 0 (sans montant fictif)
    return 0;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_storageKey);
      if (saved != null) {
        state = saved;
      }
    } catch (e) {
      debugPrint('[SgiDeclaredBalanceNotifier] Erreur chargement : $e');
    }
  }

  Future<void> updateBalance(int newBalance) async {
    state = newBalance;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, newBalance);
    } catch (e) {
      debugPrint('[SgiDeclaredBalanceNotifier] Erreur sauvegarde : $e');
    }
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

  // Calcul du solde de trésorerie net d'après toutes les opérations réelles enregistrées
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
