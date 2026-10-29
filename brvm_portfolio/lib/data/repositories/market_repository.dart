import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/models/stock.dart';
import '../../features/market/market_providers.dart';
import '../services/brvm_scraper_service.dart';

/// Origine des données lors d'un rafraîchissement
enum RefreshSource {
  liveBrvm,
  firestoreFallback,
}

/// Résultat détaillé d'une actualisation de cours
class RefreshQuotesResult {
  final List<Stock> stocks;
  final RefreshSource source;
  final bool firestoreUpdated;
  final String? errorMessage;

  const RefreshQuotesResult({
    required this.stocks,
    required this.source,
    required this.firestoreUpdated,
    this.errorMessage,
  });
}

/// Référentiel des cotations de marché BRVM
/// Stratégie hybride hautement disponible :
/// 1. Collecte directe depuis l'application via [BrvmScraperService] (site officiel brvm.org)
/// 2. Sauvegarde immédiate dans Firestore avec archivage quotidien de l'historique
/// 3. En cas d'indisponibilité du site BRVM : repli automatique sur Firestore
/// 4. En cas de coupure totale : cache statique local
class MarketRepository {
  final FirebaseFirestore? _customFirestore;
  final BrvmScraperService _scraperService;

  MarketRepository({
    FirebaseFirestore? firestore,
    BrvmScraperService? scraperService,
  })  : _customFirestore = firestore,
        _scraperService = scraperService ?? BrvmScraperService();

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
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

        return _buildStocksFromRawData(rawTitres);
      }).handleError((error) {
        debugPrint('[MarketRepository] Erreur d\'écoute Firestore : $error. Utilisation du cache local.');
        return kInitialBRVMStocks;
      });
    } catch (e) {
      debugPrint('[MarketRepository] Exception écoute Firestore : $e');
      return Stream.value(kInitialBRVMStocks);
    }
  }

  /// Rafraîchit les cours : collecte en direct depuis le site BRVM et synchronise Firestore.
  /// En cas d'échec de la collecte directe, se rabat sur Firestore.
  Future<RefreshQuotesResult> refreshQuotesFromSource({List<Stock>? currentStocks}) async {
    try {
      debugPrint('[MarketRepository] Démarrage de la collecte directe depuis la BRVM...');
      final scrapedQuotes = await _scraperService.collecterCotations();

      if (scrapedQuotes.isNotEmpty) {
        debugPrint('[MarketRepository] ✅ Collecte directe BRVM réussie (${scrapedQuotes.length} titres).');

        // Sauvegarde synchrone dans Firestore avec constitution de l'historique
        bool firestoreUpdated = false;
        String? saveError;
        try {
          await _sauvegarderDansFirestore(scrapedQuotes);
          firestoreUpdated = true;
          debugPrint('[MarketRepository] ✅ Synchronisation Firestore effectuée avec succès.');
        } catch (e) {
          saveError = e.toString();
          debugPrint('[MarketRepository] ⚠️ Erreur lors de la sauvegarde Firestore : $e');
        }

        // Met à jour la liste locale en préservant l'historique existant
        final updatedStocks = _mergeScrapedQuotes(scrapedQuotes, currentStocks: currentStocks);

        return RefreshQuotesResult(
          stocks: updatedStocks,
          source: RefreshSource.liveBrvm,
          firestoreUpdated: firestoreUpdated,
          errorMessage: saveError,
        );
      }
    } catch (e) {
      debugPrint('[MarketRepository] Collecte directe impossible ($e). Repli sur Firestore...');
    }

    // Repli automatique sur Firestore
    final fallbackStocks = await fetchLatestQuotes();
    return RefreshQuotesResult(
      stocks: fallbackStocks,
      source: RefreshSource.firestoreFallback,
      firestoreUpdated: false,
    );
  }

  /// Récupère manuellement la dernière photo des cotations depuis Firestore
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
      return _buildStocksFromRawData(rawTitres);
    } catch (e) {
      debugPrint('[MarketRepository] Erreur récupération cotations Firestore : $e');
      return kInitialBRVMStocks;
    }
  }

  /// Fusionne les cotations scrapées avec la liste de référence en conservant l'historique existant
  List<Stock> _mergeScrapedQuotes(
    List<ScrapedStockQuote> quotes, {
    List<Stock>? currentStocks,
  }) {
    final Map<String, ScrapedStockQuote> mapQuotes = {
      for (final q in quotes) q.code.toUpperCase(): q,
    };

    final baseList = (currentStocks != null && currentStocks.isNotEmpty)
        ? currentStocks
        : kInitialBRVMStocks;

    return baseList.map((stockBase) {
      final scraped = mapQuotes[stockBase.code.toUpperCase()];
      if (scraped == null) return stockBase;

      final cloture = scraped.closingPrice;
      final veille = scraped.previousClosePrice;
      final ouverture = scraped.openingPrice;

      // Conserver l'historique existant s'il en possède déjà
      final List<double> hist = List.from(stockBase.historicalPrices);
      if (hist.isEmpty) {
        if (veille > 0) hist.add(veille.toDouble());
        if (ouverture > 0 && ouverture != veille) hist.add(ouverture.toDouble());
        if (cloture > 0) hist.add(cloture.toDouble());
      } else {
        if (cloture > 0 && hist.last != cloture.toDouble()) {
          hist.add(cloture.toDouble());
        }
      }

      return stockBase.copyWith(
        currentPrice: cloture,
        previousClosePrice: veille,
        openingPrice: ouverture,
        dailyVariation: scraped.dailyVariation,
        volume: scraped.volume,
        dayHigh: [cloture, veille, ouverture, stockBase.dayHigh].reduce((a, b) => a > b ? a : b),
        dayLow: [cloture, veille, ouverture, stockBase.dayLow > 0 ? stockBase.dayLow : cloture].reduce((a, b) => a < b ? a : b),
        historicalPrices: hist.isNotEmpty ? hist : [cloture.toDouble()],
        lastUpdated: scraped.date,
      );
    }).toList();
  }

  /// Reconstruit les objets Stock depuis les données brutes Firestore avec historique réel
  List<Stock> _buildStocksFromRawData(Map<String, dynamic> rawTitres) {
    return kInitialBRVMStocks.map((stockBase) {
      final liveData = rawTitres[stockBase.code];
      if (liveData is Map<String, dynamic>) {
        final int cloture = (liveData['cours_cloture'] as num?)?.toInt() ?? stockBase.currentPrice;
        final int veille = (liveData['cours_veille'] as num?)?.toInt() ?? stockBase.previousClosePrice;
        final int ouverture = (liveData['cours_ouverture'] as num?)?.toInt() ?? stockBase.openingPrice;
        final double varPct = (liveData['variation_pct'] as num?)?.toDouble() ?? stockBase.dailyVariation;
        final int volume = (liveData['volume'] as num?)?.toInt() ?? stockBase.volume;

        // Extraction de l'historique réel accumulé dans Firestore
        final List<double> hist = [];
        final rawHist = liveData['historique'];
        if (rawHist is List) {
          for (final item in rawHist) {
            if (item is Map && item['cours'] != null) {
              hist.add((item['cours'] as num).toDouble());
            } else if (item is num) {
              hist.add(item.toDouble());
            }
          }
        }

        // Si aucun historique multi-jours n'est encore enregistré, construire la séance réelle
        if (hist.length < 2) {
          if (veille > 0) hist.add(veille.toDouble());
          if (ouverture > 0 && ouverture != veille) hist.add(ouverture.toDouble());
          if (cloture > 0 && (hist.isEmpty || hist.last != cloture.toDouble())) {
            hist.add(cloture.toDouble());
          }
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
          historicalPrices: hist.isNotEmpty ? hist : [cloture.toDouble()],
          lastUpdated: DateTime.now(),
        );
      }
      return stockBase;
    }).toList();
  }

  /// Sauvegarde les cours dans Firestore en préservant l'historique sans jamais l'écraser
  Future<void> _sauvegarderDansFirestore(List<ScrapedStockQuote> quotes) async {
    final db = _firestore;
    if (db == null) {
      throw Exception('Firestore non initialisé.');
    }

    final docRef = db.collection('systeme').doc('cotations_courantes');
    final existingDoc = await docRef.get();
    final existingTitres = (existingDoc.exists && existingDoc.data() != null)
        ? (existingDoc.data()!['titres'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, dynamic> titresMap = {};

    // Utilisation d'un WriteBatch pour garantir une écriture atomique et rapide (49 documents)
    final batch = db.batch();

    for (final q in quotes) {
      final prev = existingTitres[q.code] as Map<String, dynamic>? ?? {};
      List<dynamic> historique = [];
      if (prev['historique'] is List) {
        historique = List.from(prev['historique'] as List);
      }

      // Actualiser ou ajouter la séance du jour dans l'historique cumulé
      final idx = historique.indexWhere((h) => h is Map && h['date'] == dateStr);
      if (idx >= 0) {
        historique[idx] = {'date': dateStr, 'cours': q.closingPrice};
      } else {
        historique.add({'date': dateStr, 'cours': q.closingPrice});
      }

      // Conserver les 90 dernières séances
      if (historique.length > 90) {
        historique = historique.sublist(historique.length - 90);
      }

      titresMap[q.code] = {
        'code': q.code,
        'nom': q.name,
        'cours_cloture': q.closingPrice,
        'cours_veille': q.previousClosePrice,
        'cours_ouverture': q.openingPrice,
        'variation_pct': q.dailyVariation,
        'volume': q.volume,
        'date_maj': q.date.toIso8601String(),
        'historique': historique,
      };

      // Sauvegarde immuable quotidienne par sous-collection (historique permanent)
      final historyRef = db.collection('titres').doc(q.code).collection('cours').doc(dateStr);
      batch.set(historyRef, {
        'code': q.code,
        'date': dateStr,
        'cours': q.closingPrice,
        'cours_veille': q.previousClosePrice,
        'cours_ouverture': q.openingPrice,
        'variation_pct': q.dailyVariation,
        'volume': q.volume,
        'mis_a_jour': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Mise à jour du document global consolidé
    batch.set(docRef, {
      'titres': titresMap,
      'derniere_maj': FieldValue.serverTimestamp(),
      'source': 'direct_app_scraper',
      'date_collecte': dateStr,
      'nb_titres': quotes.length,
    }, SetOptions(merge: true));

    // Exécution du lot d'écritures
    await batch.commit();
    debugPrint('[MarketRepository] ✅ WriteBatch Firestore réussi (${quotes.length} cours + historique).');
  }
}
