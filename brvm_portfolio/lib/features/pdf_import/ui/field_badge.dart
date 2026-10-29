import 'package:flutter/material.dart';

enum BadgeType { pdf, aConfirmer, calcule, manquant }

/// Badge visuel indiquant l'origine ou l'état de validation d'un champ extrait.
class FieldBadge extends StatelessWidget {
  final BadgeType type;
  final String? label;

  const FieldBadge({
    super.key,
    required this.type,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String defaultLabel;

    switch (type) {
      case BadgeType.pdf:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.picture_as_pdf;
        defaultLabel = 'PDF';
        break;
      case BadgeType.aConfirmer:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        icon = Icons.help_outline;
        defaultLabel = 'À confirmer';
        break;
      case BadgeType.calcule:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        icon = Icons.calculate_outlined;
        defaultLabel = 'Calculé';
        break;
      case BadgeType.manquant:
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.error_outline;
        defaultLabel = 'Manquant';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label ?? defaultLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
