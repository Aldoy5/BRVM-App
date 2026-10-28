import 'package:intl/intl.dart';

/// Utilitaires de formatage spécifiques aux normes financières de la BRVM et à la langue française.
class AppFormatters {
  AppFormatters._();

  /// Formate un montant entier en FCFA avec espace comme séparateur de milliers.
  /// Exemple : 1234567 -> "1 234 567 FCFA"
  static String formatFCFA(int montant) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    // Remplacement des espaces insécables par des espaces simples pour compatibilité Android
    final formattedNumber = formatter.format(montant).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
    return '$formattedNumber FCFA';
  }

  /// Formate un montant double en FCFA (arrondi à l'entier).
  static String formatDoubleToFCFA(double montant) {
    return formatFCFA(montant.round());
  }

  /// Formate un nombre entier standard avec des espaces pour les milliers.
  /// Exemple : 1500 -> "1 500"
  static String formatInteger(int value) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(value).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
  }

  /// Formate un nombre décimal (ex: PRU) avec 2 décimales si nécessaire.
  /// Exemple : 18500.5 -> "18 500,50 FCFA"
  static String formatPriceDecimal(double value) {
    final formatter = NumberFormat('#,##0.00', 'fr_FR');
    final formattedNumber = formatter.format(value).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ');
    return '$formattedNumber FCFA';
  }

  /// Formate un pourcentage de variation avec signe explicite (+ ou -).
  /// Exemple : 2.45 -> "+2.45%", -1.2 -> "-1.20%", 0 -> "0.00%"
  static String formatVariationPercent(double variation, {int decimals = 2}) {
    final sign = variation > 0 ? '+' : '';
    final formatter = NumberFormat('0.${'0' * decimals}', 'fr_FR');
    return '$sign${formatter.format(variation)}%';
  }

  /// Formate une variation en montant FCFA avec signe explicite (+ ou -).
  /// Exemple : 25000 -> "+25 000 FCFA", -5000 -> "-5 000 FCFA", 0 -> "0 FCFA"
  static String formatVariationAmount(int amount) {
    if (amount == 0) return '0 FCFA';
    final sign = amount > 0 ? '+' : '';
    return '$sign${formatFCFA(amount)}';
  }

  /// Formate une date courte en français (ex: "28 oct. 2026").
  static String formatDate(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Formate une date complète en français (ex: "28 octobre 2026").
  static String formatDateLong(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Formate une date avec heure (ex: "28 oct. 2026 à 15:30").
  static String formatDateTime(DateTime date) {
    final dateFormatter = DateFormat('d MMM yyyy', 'fr_FR');
    final timeFormatter = DateFormat('HH:mm', 'fr_FR');
    return '${dateFormatter.format(date)} à ${timeFormatter.format(date)}';
  }

  /// Formate une mention "Cours au [date]" pour l'en-tête du portefeuille.
  static String formatMarketQuoteDate(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy', 'fr_FR');
    return 'Cours au ${formatter.format(date)}';
  }
}

/// Raccourci global demandé par les spécifications
String formatFCFA(int montant) => AppFormatters.formatFCFA(montant);
