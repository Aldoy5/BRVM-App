import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/stock.dart';
import '../../features/market/market_providers.dart';

/// Référentiel des cotations de marché BRVM
/// Gère la synchronisation continue temps-réel via Firestore (document unique `systeme/cotations_courantes`)
/// avec basculement automatique et persistance hors-ligne.
class MarketRepository {
  final FirebaseFirestore? _customFirestore;

  MarketRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      // Firebase non initialisé (ex: mode test / démo autonome)
      return null;
    }
  }

  /// Écoute le flux temps réel continu des cotations courantes BRVM depuis Firestore
  Stream<List<Stock>> watchMarketQuotes() {
    final db = _firestore;
    if (db == null) {
      return Stream.value(kInitialBRVMStocks);
    }

    try {
      return db
          .collection('systeme')
          .doc('cotations_courantes')
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return kInitialBRVMStocks;
        }

        final data = snapshot.data()!;
        final rawTitres = data['titres'];
        if (rawTitres is! Map<String, dynamic>) {
          return kInitialBRVMStocks;
        }

        // Met à jour la liste des 48 titres de base avec les données temps réel reçues
        return kInitialBRVMStocks.map((stockBase) {
          final liveData = rawTitres[stockBase.code];
          if (liveData is Map<String, dynamic>) {
            final int cloture = (liveData['cours_cloture'] as num?)?.toInt() ?? stockBase.currentPrice;
            final int veille = (liveData['cours_veille'] as num?)?.toInt() ?? stockBase.previousClosePrice;
            final int ouverture = (liveData['cours_ouverture'] as num?)?.toInt() ?? stockBase.openingPrice;
            final double varPct = (liveData['variation_pct'] as num?)?.toDouble() ?? stockBase.dailyVariation;
            final int volume = (liveData['volume'] as num?)?.toInt() ?? stockBase.volume;

            final hist = [...stockBase.historicalPrices];
            if (hist.isNotEmpty && hist.last != cloture.toDouble()) {
              hist.add(cloture.toDouble());
              if (hist.length > 7) hist.removeAt(0);
            }

            final dayHigh = [cloture, veille, ouverture, stockBase.dayHigh].reduce((a, b) => a > b ? a : b);
            final dayLow = [cloture, veille, ouverture, stockBase.dayLow > 0 ? stockBase.dayLow : cloture].reduce((a, b) => a < b ? a : b);

            return stockBase.copyWith(
              currentPrice: cloture,
              previousClosePrice: veille,
              openingPrice: ouverture,
              dailyVariation: varPct,
              volume: volume,
              dayHigh: dayHigh,
              dayLow: dayLow,
              historicalPrices: hist,
              lastUpdated: DateTime.now(),
            );
          }
          return stockBase;
        }).toList();
      }).handleError((error) {
        debugPrint('[MarketRepository] Erreur d\'écoute Firestore : $error. Utilisation du cache local.');
        return kInitialBRVMStocks;
      });
    } catch (e) {
      debugPrint('[MarketRepository] Exception écoute Firestore : $e');
      return Stream.value(kInitialBRVMStocks);
    }
  }

  /// Récupère manuellement la dernière photo des cotations
  Future<List<Stock>> fetchLatestQuotes() async {
    final db = _firestore;
    if (db == null) {
      return kInitialBRVMStocks;
    }

    try {
      final doc = await db.collection('systeme').doc('cotations_courantes').get();
      if (!doc.exists || doc.data() == null) {
        return kInitialBRVMStocks;
      }
      final rawTitres = doc.data()!['titres'] as Map<String, dynamic>? ?? {};
      return kInitialBRVMStocks.map((stockBase) {
        final liveData = rawTitres[stockBase.code];
        if (liveData is Map<String, dynamic>) {
          final int cloture = (liveData['cours_cloture'] as num?)?.toInt() ?? stockBase.currentPrice;
          final int veille = (liveData['cours_veille'] as num?)?.toInt() ?? stockBase.previousClosePrice;
          final int ouverture = (liveData['cours_ouverture'] as num?)?.toInt() ?? stockBase.openingPrice;
          final double varPct = (liveData['variation_pct'] as num?)?.toDouble() ?? stockBase.dailyVariation;
          final int volume = (liveData['volume'] as num?)?.toInt() ?? stockBase.volume;

          final dayHigh = [cloture, veille, ouverture, stockBase.dayHigh].reduce((a, b) => a > b ? a : b);
          final dayLow = [cloture, veille, ouverture, stockBase.dayLow > 0 ? stockBase.dayLow : cloture].reduce((a, b) => a < b ? a : b);

          return stockBase.copyWith(
            currentPrice: cloture,
            previousClosePrice: veille,
            openingPrice: ouverture,
            dailyVariation: varPct,
            volume: volume,
            dayHigh: dayHigh,
            dayLow: dayLow,
            lastUpdated: DateTime.now(),
          );
        }
        return stockBase;
      }).toList();
    } catch (e) {
      debugPrint('[MarketRepository] Erreur récupération cotations : $e');
      return kInitialBRVMStocks;
    }
  }

  /// Vérifie et initialise le document des cotations Firestore si absent
  Future<void> seedInitialQuotesIfEmpty() async {
    final db = _firestore;
    if (db == null) return;

    try {
      final docRef = db.collection('systeme').doc('cotations_courantes');
      final doc = await docRef.get();
      if (!doc.exists) {
        final Map<String, dynamic> titresMap = {};
        for (final s in kInitialBRVMStocks) {
          titresMap[s.code] = {
            'cours_cloture': s.currentPrice,
            'cours_veille': s.previousClosePrice,
            'cours_ouverture': s.openingPrice > 0 ? s.openingPrice : s.previousClosePrice,
            'variation_pct': s.dailyVariation,
            'volume': s.volume,
          };
        }
        await docRef.set({
          'titres': titresMap,
          'derniere_maj': FieldValue.serverTimestamp(),
          'source': 'auto_seed_initial',
        });
        debugPrint('[MarketRepository] Document systeme/cotations_courantes initialisé avec succès.');
      }
    } catch (e) {
      debugPrint('[MarketRepository] Erreur lors de l\'initialisation des cotations : $e');
    }
  }
}
