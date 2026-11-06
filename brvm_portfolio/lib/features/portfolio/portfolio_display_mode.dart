import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'affichage de la performance du portefeuille.
enum PortfolioDisplayMode {
  /// Performance globale (depuis l'achat / PRU).
  total,

  /// Performance de la séance en direct (Aujourd'hui vs Clôture veille).
  session,

  /// Ce qui a été gagné la veille (Clôture veille vs Avant-veille).
  yesterday,
}

/// Notifier qui gère le mode d'affichage sélectionné (toggle Global / Aujourd'hui / Hier).
class PortfolioDisplayModeNotifier extends Notifier<PortfolioDisplayMode> {
  @override
  PortfolioDisplayMode build() => PortfolioDisplayMode.total;

  void setMode(PortfolioDisplayMode mode) => state = mode;
}

/// Provider du mode d'affichage du portefeuille.
final portfolioDisplayModeProvider =
    NotifierProvider<PortfolioDisplayModeNotifier, PortfolioDisplayMode>(
        PortfolioDisplayModeNotifier.new);
