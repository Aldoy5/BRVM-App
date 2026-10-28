import 'package:flutter/material.dart';

/// Constantes visuelles et métier pour l'application BRVM Portfolio.
class AppColors {
  AppColors._();

  // Couleur primaire : Bleu nuit professionnel
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF534BAE);
  static const Color primaryDark = Color(0xFF000051);

  // Couleurs d'accent et de surface
  static const Color secondary = Color(0xFF0D47A1);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Couleurs de performance financière
  // Vert pour les gains
  static const Color gain = Color(0xFF2E7D32);
  static const Color gainLight = Color(0xFFE8F5E9);

  // Rouge pour les pertes
  static const Color loss = Color(0xFFD32F2F);
  static const Color lossLight = Color(0xFFFFEBEE);

  // Gris pour la neutralité (0%)
  static const Color neutral = Color(0xFF757575);
  static const Color neutralLight = Color(0xFFEEEEEE);

  // Textes
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9AA0A6);

  // Séparateurs et bordures
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
}

/// Constantes métier pour les calculs de frais et paramètres BRVM
class AppConstants {
  AppConstants._();

  // Nom de l'application
  static const String appName = 'BRVM Portfolio';

  // Taux de frais de courtage par défaut (ex: 1.18% TTC standard SGI en zone UEMOA)
  static const double defaultFeeRatePercent = 1.18;

  // Clé pour stockage éventuel
  static const String sgiBalancePrefKey = 'user_sgi_balance';
}
