import 'package:flutter/material.dart';
import 'constants.dart';
import 'formatters.dart';

/// Extensions utiles sur les types primitifs et le BuildContext
extension IntExtensions on int {
  /// Convertit un entier en format monétaire FCFA : 10000 -> "10 000 FCFA"
  String toFCFA() => AppFormatters.formatFCFA(this);

  /// Convertit une variation entière en FCFA avec signe (+/-)
  String toVariationFCFA() => AppFormatters.formatVariationAmount(this);

  /// Formate un entier avec séparateurs de milliers
  String toFormattedString() => AppFormatters.formatInteger(this);

  /// Renvoie la couleur associée selon le signe (gain, perte ou neutre)
  Color get financialColor {
    if (this > 0) return AppColors.gain;
    if (this < 0) return AppColors.loss;
    return AppColors.neutral;
  }
}

extension DoubleExtensions on double {
  /// Convertit un double en format monétaire FCFA
  String toFCFA() => AppFormatters.formatDoubleToFCFA(this);

  /// Convertit un double en chaîne de variation en pourcentage : 2.5 -> "+2.50%"
  String toVariationPercent({int decimals = 2}) =>
      AppFormatters.formatVariationPercent(this, decimals: decimals);

  /// Renvoie la couleur associée selon le signe (gain, perte ou neutre)
  Color get financialColor {
    if (this > 0.0001) return AppColors.gain;
    if (this < -0.0001) return AppColors.loss;
    return AppColors.neutral;
  }

  /// Renvoie la couleur d'arrière-plan pastel correspondante
  Color get financialBackgroundColor {
    if (this > 0.0001) return AppColors.gainLight;
    if (this < -0.0001) return AppColors.lossLight;
    return AppColors.neutralLight;
  }
}

extension DateTimeExtensions on DateTime {
  /// Formate la date au format court français : "28 oct. 2026"
  String toShortDate() => AppFormatters.formatDate(this);

  /// Formate la date au format complet français : "28 octobre 2026"
  String toLongDate() => AppFormatters.formatDateLong(this);

  /// Formate la date avec l'heure : "28 oct. 2026 à 15:30"
  String toDateTimeString() => AppFormatters.formatDateTime(this);

  /// Mention "Cours au [date]"
  String toMarketQuoteMention() => AppFormatters.formatMarketQuoteDate(this);
}

extension BuildContextExtensions on BuildContext {
  /// Accès rapide au ThemeData
  ThemeData get theme => Theme.of(this);

  /// Accès rapide au TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Accès rapide au ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Affiche rapidement un SnackBar informatif
  void showAppSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: isError
            ? AppColors.loss
            : (isSuccess ? AppColors.gain : AppColors.primary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
