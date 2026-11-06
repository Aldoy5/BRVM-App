import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brvm_portfolio/core/constants.dart';
import 'package:brvm_portfolio/core/models/position.dart';
import 'package:brvm_portfolio/features/portfolio/widgets/position_list_tile.dart';

void main() {
  group('PositionListTile - Poids du portefeuille & Gain/Perte', () {
    testWidgets('affiche le poids du portefeuille avec barre de progression verte en cas de gain', (tester) async {
      const posGagnante = Position(
        stockCode: 'CIEC',
        stockName: 'CIE CI',
        quantity: 45,
        pru: 5290.0,
        currentPrice: 5500, // Valo = 45 * 5500 = 247 500, Investi = 45 * 5290 = 238 050 -> Gain = +9 450
        previousClosePrice: 5400,
        dailyVariation: 1.85,
      );

      // Portefeuille total de 1 000 000 FCFA -> Poids CIEC = 247 500 / 1 000 000 = 24.75% -> ~24.8% ou 24.7%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PositionListTile(
              position: posGagnante,
              portfolioTotalValuation: 1000000,
            ),
          ),
        ),
      );

      // 1. Ticker et quantité
      expect(find.text('CIEC'), findsOneWidget);
      expect(find.text('45 titres'), findsOneWidget);

      // 2. Gain affiché avec signe +
      expect(find.textContaining('+9 450 FCFA'), findsOneWidget);

      // 3. Poids affiché
      expect(find.textContaining('24,8 % du portefeuille'), findsOneWidget);

      // 4. Barre de progression présente et colorée en vert
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.2475, 0.001));

      final animation = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(animation.value, equals(AppColors.gain));
    });

    testWidgets('affiche une barre de progression rouge en cas de moins-value (perte)', (tester) async {
      const posPerdante = Position(
        stockCode: 'SAFC',
        stockName: 'SAFCA',
        quantity: 40,
        pru: 5354.0,
        currentPrice: 3760, // Valo = 40 * 3760 = 150 400, Investi = 214 160 -> Perte = -63 760
        previousClosePrice: 3800,
        dailyVariation: -1.05,
      );

      // Portefeuille total de 1 000 000 FCFA -> Poids SAFCA = 15.04%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PositionListTile(
              position: posPerdante,
              portfolioTotalValuation: 1000000,
            ),
          ),
        ),
      );

      // 1. Ticker
      expect(find.text('SAFC'), findsOneWidget);

      // 2. Moins-value affichée avec signe -
      expect(find.textContaining('-63 760 FCFA'), findsOneWidget);

      // 3. Poids affiché
      expect(find.textContaining('15,0 % du portefeuille'), findsOneWidget);

      // 4. Barre de progression présente et colorée en rouge
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.1504, 0.001));

      final animation = progressIndicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(animation.value, equals(AppColors.loss));
    });
  });
}
