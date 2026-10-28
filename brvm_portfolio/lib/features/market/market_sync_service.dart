import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_providers.dart';

/// Statut de la séance de négociation de la BRVM
enum BrvmSessionStatus {
  open('Séance ouverte (en direct différé 15 min)', true),
  preOpen('Pré-ouverture (accumulation des ordres)', true),
  closed('Séance fermée', false);

  final String label;
  final bool isLive;
  const BrvmSessionStatus(this.label, this.isLive);
}

/// Service de gestion de la mise à jour continue des cours du marché BRVM.
/// Gère la détection des horaires de cotation (09h45 - 14h30 GMT),
/// le cycle périodique continue et le rafraîchissement manuel.
class MarketSyncService {
  final Ref _ref;
  Timer? _pollingTimer;
  Timer? _statusTimer;

  // Intervalle de mise à jour automatique continue pendant la séance (ex: chaque minute)
  static const Duration pollingInterval = Duration(minutes: 1);

  MarketSyncService(this._ref);

  /// Détermine si la BRVM est actuellement en séance selon l'heure GMT
  /// Séance officielle : Lundi au Vendredi, 09h45 à 14h30 GMT (fuseau Abidjan)
  static BrvmSessionStatus determineSessionStatus([DateTime? gmtTime]) {
    final now = gmtTime ?? DateTime.now().toUtc();

    // Samedi et Dimanche : Marché fermé
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return BrvmSessionStatus.closed;
    }

    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final preOpenStart = 9 * 60; // 09h00 GMT
    final sessionStart = 9 * 60 + 45; // 09h45 GMT
    final sessionEnd = 14 * 60 + 30; // 14h30 GMT

    if (minutesSinceMidnight >= sessionStart && minutesSinceMidnight <= sessionEnd) {
      return BrvmSessionStatus.open;
    } else if (minutesSinceMidnight >= preOpenStart && minutesSinceMidnight < sessionStart) {
      return BrvmSessionStatus.preOpen;
    }

    return BrvmSessionStatus.closed;
  }

  /// Démarre le cycle de mise à jour continue en tâche de fond
  void startContinuousSync() {
    _pollingTimer?.cancel();
    _statusTimer?.cancel();

    // Timer de mise à jour périodique des cotations
    _pollingTimer = Timer.periodic(pollingInterval, (_) {
      final status = determineSessionStatus();
      if (status.isLive) {
        // Rafraîchir les cotations en continu pendant les heures de marché
        _ref.read(marketStocksProvider.notifier).refreshLiveQuotes();
      }
    });

    // Timer d'actualisation de statut de séance toutes les 30 secondes
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _ref.read(sessionStatusNotifierProvider.notifier).checkStatus();
    });
  }

  /// Arrête la synchronisation périodique
  void stopContinuousSync() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _statusTimer?.cancel();
    _statusTimer = null;
  }
}

/// Notifier pour le statut de la séance réévalué dynamiquement
class SessionStatusNotifier extends Notifier<BrvmSessionStatus> {
  @override
  BrvmSessionStatus build() {
    return MarketSyncService.determineSessionStatus();
  }

  void checkStatus() {
    state = MarketSyncService.determineSessionStatus();
  }
}

final sessionStatusNotifierProvider =
    NotifierProvider<SessionStatusNotifier, BrvmSessionStatus>(SessionStatusNotifier.new);

final marketSyncServiceProvider = Provider<MarketSyncService>((ref) {
  final service = MarketSyncService(ref);
  service.startContinuousSync();
  ref.onDispose(() => service.stopContinuousSync());
  return service;
});

final currentSessionStatusProvider = Provider<BrvmSessionStatus>((ref) {
  return ref.watch(sessionStatusNotifierProvider);
});
