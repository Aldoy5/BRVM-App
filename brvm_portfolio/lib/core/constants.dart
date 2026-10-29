import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary: Dark green (maquette)
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF0D3B0F);

  // Surface and backgrounds
  static const Color secondary = Color(0xFF2E7D32);
  static const Color background = Color(0xFFF5F0EB); // Warm beige
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEDE8E1); // Warm beige for tabs

  // Financial colors stay the same
  static const Color gain = Color(0xFF2E7D32);
  static const Color gainLight = Color(0xFFE8F5E9);
  static const Color loss = Color(0xFFC62828);
  static const Color lossLight = Color(0xFFFFEBEE);
  static const Color neutral = Color(0xFF757575);
  static const Color neutralLight = Color(0xFFEEEEEE);

  // Text colors - darker, warmer
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFFA0A0A0);

  // Borders - lighter
  static const Color border = Color(0xFFE0DDD8);
  static const Color divider = Color(0xFFEDE8E1);
}

class AppConstants {
  AppConstants._();
  static const String appName = 'BRVM Portfolio';
  static const double defaultFeeRatePercent = 1.18;
  /// Taux de frais par défaut en points de base (1.18% = 118 pb).
  static const int defaultFeeRateBp = 118;
  static const String sgiBalancePrefKey = 'user_sgi_balance';
}
