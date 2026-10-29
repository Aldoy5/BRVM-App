import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/operation.dart';
import '../../data/repositories/operations_repository.dart';
import '../auth/auth_providers.dart';

/// Provider pour accéder au repository d'opérations Firestore lié à l'utilisateur connecté
final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  return OperationsRepository(userId: uid);
});

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

/// Notifier pour la liste des opérations de l'utilisateur connecté (isolé dans Firestore)
class OperationsNotifier extends Notifier<List<Operation>> {
  static const _legacyStorageKey = 'user_real_operations_v1';
  StreamSubscription<List<Operation>>? _firestoreSub;
  bool _migrationAttempted = false;

  @override
  List<Operation> build() {
    final uid = ref.watch(currentUserIdProvider);

    ref.onDispose(() {
      _firestoreSub?.cancel();
    });

    if (uid == null) {
      _firestoreSub?.cancel();
      _firestoreSub = null;
      return kInitialOperations;
    }

    _subscribeToUserOperations(uid);
    return kInitialOperations;
  }

  void _subscribeToUserOperations(String uid) {
    _firestoreSub?.cancel();
    final repo = ref.read(operationsRepositoryProvider);

    _firestoreSub = repo.watchOperations().listen(
      (firestoreOps) async {
        // Migration automatique des données locales antérieures si la collection Firestore est vierge
        if (firestoreOps.isEmpty && !_migrationAttempted) {
          _migrationAttempted = true;
          await _tryMigrateLegacyOperations(uid, repo);
          return;
        }
        state = firestoreOps;
      },
      onError: (e) {
        debugPrint('[OperationsNotifier] Erreur flux Firestore : $e');
      },
    );
  }

  /// Migre les opérations sauvegardées en local vers le compte de l'utilisateur
  Future<void> _tryMigrateLegacyOperations(
    String uid,
    OperationsRepository repo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'migrated_to_firestore_$uid';
      if (prefs.getBool(migrationKey) == true) return;

      final raw = prefs.getString(_legacyStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final legacyOps = list
            .map((item) => Operation.fromJson(item as Map<String, dynamic>))
            .toList();

        if (legacyOps.isNotEmpty) {
          debugPrint('[OperationsNotifier] Migration de ${legacyOps.length} opérations vers Firestore ($uid)...');
          for (final op in legacyOps) {
            await repo.saveOperation(op);
          }
          await prefs.setBool(migrationKey, true);
        }
      }
    } catch (e) {
      debugPrint('[OperationsNotifier] Erreur migration locale vers Firestore : $e');
    }
  }

  Future<void> addOperation(Operation operation) async {
    state = [operation, ...state];
    final repo = ref.read(operationsRepositoryProvider);
    await repo.saveOperation(operation);
  }

  Future<void> updateOperation(Operation updated) async {
    state = [
      for (final op in state)
        if (op.id == updated.id) updated else op,
    ];
    final repo = ref.read(operationsRepositoryProvider);
    await repo.saveOperation(updated);
  }

  Future<void> deleteOperation(String id) async {
    state = state.where((op) => op.id != id).toList();
    final repo = ref.read(operationsRepositoryProvider);
    await repo.deleteOperation(id);
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
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return 0;
    _loadBalance(uid);
    return 0;
  }

  Future<void> _loadBalance(String uid) async {
    try {
      final repo = ref.read(operationsRepositoryProvider);
      final remoteBalance = await repo.getSgiDeclaredBalance();
      if (remoteBalance != null) {
        state = remoteBalance;
        return;
      }

      // Fallback local propre à cet utilisateur
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('user_sgi_balance_$uid');
      if (saved != null) {
        state = saved;
      }
    } catch (e) {
      debugPrint('[SgiDeclaredBalanceNotifier] Erreur chargement : $e');
    }
  }

  Future<void> updateBalance(int newBalance) async {
    state = newBalance;
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    try {
      final repo = ref.read(operationsRepositoryProvider);
      await repo.saveSgiDeclaredBalance(newBalance);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_sgi_balance_$uid', newBalance);
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
