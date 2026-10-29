import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brvm_portfolio/app.dart';

void main() {
  testWidgets('Test de chargement de l\'application BRVM Portfolio (affiche la page de connexion)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BrvmPortfolioApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Vérifie que l'écran de connexion s'affiche pour un utilisateur non connecté
    expect(find.text('Connectez-vous pour accéder à vos titres'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
