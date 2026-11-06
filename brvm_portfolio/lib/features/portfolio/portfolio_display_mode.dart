import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'affichage de la performance du portefeuille.
enum PortfolioDisplayMode {
  /// Performance globale (depuis l'achat / PRU).
  total,

  /// Performance de la séance (vs clôture de la veille).
  session,
}

/// Notifier qui gère le mode d'affichage sélectionné (toggle Global / Séance).
class PortfolioDisplayModeNotifier extends Notifier<PortfolioDisplayMode> {
  @override
  PortfolioDisplayMode build() => PortfolioDisplayMode.total;

  void setMode(PortfolioDisplayMode mode) => state = mode;

  void toggle() {
    state = state == PortfolioDisplayMode.total
        ? PortfolioDisplayMode.session
        : PortfolioDisplayMode.total;
  }
}

/// Provider du mode d'affichage du portefeuille.
final portfolioDisplayModeProvider =
    NotifierProvider<PortfolioDisplayModeNotifier, PortfolioDisplayMode>(
        PortfolioDisplayModeNotifier.new);
