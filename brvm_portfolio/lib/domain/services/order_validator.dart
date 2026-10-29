import '../models/parsed_order.dart';

/// Contexte de validation fourni par l'application pour contrôler l'import.
class ValidationContext {
  /// IDs des opérations déjà enregistrées (pour détection de doublon).
  final Set<String> operationIdsExistants;

  /// Codes des titres connus dans le référentiel marché.
  final Set<String> codesTitresConnus;

  /// Date de référence pour la vérification d'expiration (par défaut DateTime.now()).
  final DateTime? dateReference;

  const ValidationContext({
    this.operationIdsExistants = const {},
    this.codesTitresConnus = const {},
    this.dateReference,
  });
}

/// Valide un ordre parsé et retourne la liste des alertes.
List<Alerte> validerImportOrdre(ParsedOrder parsed, ValidationContext contexte) {
  final alertes = <Alerte>[];

  // E_DOUBLON: bici_bourse_{numero} déjà présent
  if (parsed.numeroOrdre != null) {
    final id = '${parsed.sgiSlug}_${parsed.numeroOrdre}';
    if (contexte.operationIdsExistants.contains(id)) {
      alertes.add(const Alerte(
        code: 'E_DOUBLON',
        severite: Severite.bloquant,
        message: 'Cet ordre est déjà enregistré.',
      ));
    }
  }

  // E_CHAMP_MANQUANT
  if (parsed.quantite == null) {
    alertes.add(const Alerte(
      code: 'E_CHAMP_MANQUANT',
      severite: Severite.bloquant,
      message: 'Quantité non spécifiée.',
    ));
  }
  if (parsed.codeTitre == null) {
    alertes.add(const Alerte(
      code: 'E_CHAMP_MANQUANT',
      severite: Severite.bloquant,
      message: 'Code titre non spécifié.',
    ));
  }
  if (parsed.sens == null) {
    alertes.add(const Alerte(
      code: 'E_CHAMP_MANQUANT',
      severite: Severite.bloquant,
      message: 'Sens de l\'opération non spécifié.',
    ));
  }

  // E_QTE_HORS_BORNES: quantite < 1
  if (parsed.quantite != null && parsed.quantite! < 1) {
    alertes.add(const Alerte(
      code: 'E_QTE_HORS_BORNES',
      severite: Severite.bloquant,
      message: 'La quantité doit être supérieure ou égale à 1.',
    ));
  }

  // W_TITRE_INCONNU
  if (parsed.codeTitre != null &&
      contexte.codesTitresConnus.isNotEmpty &&
      !contexte.codesTitresConnus.contains(parsed.codeTitre!.toUpperCase())) {
    alertes.add(Alerte(
      code: 'W_TITRE_INCONNU',
      severite: Severite.alerte,
      message: 'Titre "${parsed.codeTitre}" inconnu dans le référentiel BRVM.',
    ));
  }

  // W_ORDRE_EXPIRE
  final refDate = contexte.dateReference ?? DateTime.now();
  if (parsed.dateValidite != null && parsed.dateValidite!.isBefore(refDate)) {
    alertes.add(const Alerte(
      code: 'W_ORDRE_EXPIRE',
      severite: Severite.info,
      message: 'Ordre expiré : confirme qu\'il a bien été exécuté.',
    ));
  }

  // I_EXTRACTION_PARTIELLE
  if (parsed.numeroOrdre == null ||
      parsed.quantite == null ||
      parsed.codeTitre == null ||
      parsed.prixLimite == null ||
      parsed.dateValidite == null ||
      parsed.recuLe == null) {
    alertes.add(const Alerte(
      code: 'I_EXTRACTION_PARTIELLE',
      severite: Severite.info,
      message: 'Certains champs n\'ont pas pu être lus.',
    ));
  }

  return alertes;
}

/// Vérifie si le prix saisi dépasse la limite de l'ordre.
Alerte? verifierPrixLimite({required int prixSaisi, required int prixLimite}) {
  if (prixSaisi > prixLimite) {
    return Alerte(
      code: 'E_PRIX_SUP_LIMITE',
      severite: Severite.bloquant,
      message: 'Un achat ne peut pas être exécuté au-dessus de sa limite ($prixLimite FCFA).',
    );
  }
  return null;
}

/// Vérifie si la date d'exécution est dans la fenêtre [réception ; validité].
Alerte? verifierDateFenetre({
  required DateTime date,
  DateTime? recuLe,
  DateTime? dateValidite,
}) {
  if (recuLe != null && date.isBefore(recuLe)) {
    return const Alerte(
      code: 'W_DATE_HORS_FENETRE',
      severite: Severite.alerte,
      message: 'Date d\'exécution antérieure à la réception de l\'ordre.',
    );
  }
  if (dateValidite != null && date.isAfter(dateValidite)) {
    return const Alerte(
      code: 'W_DATE_HORS_FENETRE',
      severite: Severite.alerte,
      message: 'Date d\'exécution postérieure à la validité de l\'ordre.',
    );
  }
  return null;
}
