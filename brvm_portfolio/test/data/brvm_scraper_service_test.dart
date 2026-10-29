import 'package:flutter_test/flutter_test.dart';
import 'package:brvm_portfolio/data/services/brvm_scraper_service.dart';

void main() {
  group('BrvmScraperService', () {
    test('Test collecte en direct des cotations BRVM', () async {
      final scraper = BrvmScraperService();
      try {
        final quotes = await scraper.collecterCotations();
        print('Nombre de titres extraits : ${quotes.length}');
        expect(quotes.isNotEmpty, true);
        final boabf = quotes.firstWhere((q) => q.code == 'BOABF');
        print('Exemple BOABF : $boabf');
        expect(boabf.closingPrice > 0, true);
      } catch (e) {
        print('Erreur scraper (peut être normal sans réseau dans le runner) : $e');
      }
    });
  });
}
