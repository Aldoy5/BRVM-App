import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Modèle d'une cotation brute extraite du site officiel de la BRVM
class ScrapedStockQuote {
  final String code;
  final String name;
  final int closingPrice;
  final int previousClosePrice;
  final int openingPrice;
  final double dailyVariation;
  final int volume;
  final DateTime date;

  const ScrapedStockQuote({
    required this.code,
    required this.name,
    required this.closingPrice,
    required this.previousClosePrice,
    required this.openingPrice,
    required this.dailyVariation,
    required this.volume,
    required this.date,
  });

  @override
  String toString() {
    return 'ScrapedQuote($code: $closingPrice FCFA, var: $dailyVariation%, vol: $volume)';
  }
}

/// Service autonome de collecte directe des cours sur le site de la BRVM
class BrvmScraperService {
  static const String brvmDirectUrl = 'https://www.brvm.org/fr/cours-actions/0';

  // Proxies de secours pour contourner les restrictions CORS sur le Web (navigateur)
  static const List<String> corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?url=',
  ];

  final http.Client _client;

  BrvmScraperService({http.Client? client}) : _client = client ?? http.Client();

  /// Collecte directe des cotations avec stratégie multi-sources :
  /// 1. Requête directe vers brvm.org (parfait sur Mobile / Desktop)
  /// 2. Si échec ou sur Web : proxies CORS
  Future<List<ScrapedStockQuote>> collecterCotations() async {
    final List<String> urlsToTry = [];

    if (kIsWeb) {
      // Sur Web, privilégier d'abord les proxies CORS pour éviter les erreurs de console CORS
      for (final proxy in corsProxies) {
        urlsToTry.add('$proxy${Uri.encodeComponent(brvmDirectUrl)}');
      }
      urlsToTry.add(brvmDirectUrl);
    } else {
      // Sur Mobile / Desktop, direct en priorité
      urlsToTry.add(brvmDirectUrl);
      for (final proxy in corsProxies) {
        urlsToTry.add('$proxy${Uri.encodeComponent(brvmDirectUrl)}');
      }
    }

    String? lastError;

    for (final url in urlsToTry) {
      try {
        debugPrint('[BrvmScraper] Tentative de récupération depuis : $url');
        final response = await _client.get(
          Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml',
            'Accept-Language': 'fr-FR,fr;q=0.9',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final quotes = _parseHtmlTable(response.body);
          if (quotes.isNotEmpty) {
            debugPrint('[BrvmScraper] ✅ ${quotes.length} cotations extraites avec succès depuis BRVM.');
            return quotes;
          }
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[BrvmScraper] Échec sur $url : $e');
      }
    }

    throw Exception(
      'Impossible de collecter les cours en direct depuis la BRVM : ${lastError ?? "Aucune donnée"}',
    );
  }

  /// Parse le tableau HTML des actions de la BRVM
  List<ScrapedStockQuote> _parseHtmlTable(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final tables = document.querySelectorAll('table');

    for (final table in tables) {
      final thElements = table.querySelectorAll('th');
      if (thElements.length < 5) continue;

      int colSymbole = -1;
      int colNom = -1;
      int colVolume = -1;
      int colVeille = -1;
      int colOuverture = -1;
      int colCloture = -1;
      int colVariation = -1;

      for (var i = 0; i < thElements.length; i++) {
        final text = _normaliserTexte(thElements[i].text);
        if (text.contains('symbole') || text.contains('code') || text.contains('ticker')) {
          colSymbole = i;
        } else if (text.contains('nom') || text.contains('titre') || text.contains('valeur')) {
          colNom = i;
        } else if (text.contains('volume') || text.contains('quantite')) {
          colVolume = i;
        } else if (text.contains('veille') || text.contains('precedent')) {
          colVeille = i;
        } else if (text.contains('ouverture') || text.contains('open')) {
          colOuverture = i;
        } else if (text.contains('cloture') || text.contains('cours') || text.contains('dernier')) {
          colCloture = i;
        } else if (text.contains('variation') || text.contains('var')) {
          colVariation = i;
        }
      }

      // Si le tableau ressemble bien au tableau de cotations
      if (colSymbole != -1 && (colCloture != -1 || colVeille != -1)) {
        colVolume = colVolume != -1 ? colVolume : 2;
        colVeille = colVeille != -1 ? colVeille : 3;
        colOuverture = colOuverture != -1 ? colOuverture : 4;
        colCloture = colCloture != -1 ? colCloture : 5;
        colVariation = colVariation != -1 ? colVariation : 6;

        final rows = table.querySelectorAll('tbody tr');
        final results = <ScrapedStockQuote>[];
        final now = DateTime.now();

        for (final row in rows) {
          final cells = row.querySelectorAll('td');
          if (cells.length <= colSymbole) continue;

          final code = cells[colSymbole].text.trim().toUpperCase();
          if (code.isEmpty || code.length < 3 || code.length > 6) continue;

          final nom = colNom != -1 && colNom < cells.length
              ? cells[colNom].text.trim()
              : code;
          final volume = colVolume < cells.length
              ? _parseEntierFCFA(cells[colVolume].text)
              : 0;
          final coursVeille = colVeille < cells.length
              ? _parseEntierFCFA(cells[colVeille].text)
              : 0;
          final coursOuverture = colOuverture < cells.length
              ? _parseEntierFCFA(cells[colOuverture].text)
              : coursVeille;
          final coursCloture = colCloture < cells.length
              ? _parseEntierFCFA(cells[colCloture].text)
              : (coursOuverture > 0 ? coursOuverture : coursVeille);
          final variationPct = colVariation < cells.length
              ? _parseVariationPct(cells[colVariation].text)
              : 0.0;

          if (coursCloture > 0 || coursVeille > 0) {
            results.add(
              ScrapedStockQuote(
                code: code,
                name: nom,
                closingPrice: coursCloture > 0 ? coursCloture : coursVeille,
                previousClosePrice: coursVeille > 0 ? coursVeille : coursCloture,
                openingPrice: coursOuverture > 0 ? coursOuverture : coursVeille,
                dailyVariation: variationPct,
                volume: volume,
                date: now,
              ),
            );
          }
        }

        if (results.isNotEmpty) {
          return results;
        }
      }
    }

    return [];
  }

  static String _normaliserTexte(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static int _parseEntierFCFA(String str) {
    if (str.isEmpty) return 0;
    final clean = str.replaceAll(RegExp(r'[\s\u00A0\u202F\.]'), '');
    return int.tryParse(clean) ?? 0;
  }

  static double _parseVariationPct(String str) {
    if (str.isEmpty) return 0.0;
    final clean = str
        .replaceAll('%', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
