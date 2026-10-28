import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brvm_portfolio/app.dart';

void main() {
  testWidgets('Test de chargement de l\'application BRVM Portfolio', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BrvmPortfolioApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Vérifie que l'écran Portefeuille s'affiche correctement avec sa valorisation totale
    expect(find.text('Valorisation totale'), findsOneWidget);
  });
}
