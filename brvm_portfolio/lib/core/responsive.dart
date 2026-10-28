import 'package:flutter/material.dart';

/// Breakpoints et utilitaires responsive pour l'application BRVM Portfolio.
/// Sur écrans larges (web/desktop), le contenu est centré avec une largeur maximale
/// pour éviter l'étirement et conserver une UX mobile-first agréable.
class Responsive {
  Responsive._();

  /// Largeur maximale du contenu principal (simule un écran mobile centré)
  static const double maxContentWidth = 600;

  /// Seuil au-delà duquel on utilise un layout desktop (NavigationRail)
  static const double desktopBreakpoint = 840;

  /// Vérifie si l'écran est assez large pour le layout desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Vérifie si l'écran est en mode mobile/tablette portrait
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < desktopBreakpoint;
}

/// Widget enveloppant le contenu avec une largeur maximale et un centrage horizontal.
/// À utiliser dans les écrans pour contraindre la largeur sur grand écran.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return content;
  }
}
