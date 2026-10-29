import '../../../domain/models/parsed_order.dart';
import '../../../domain/services/frais_calculator.dart';
import 'pdf_text_extractor.dart';

/// Parseur spécialisé pour les ordres d'achat émis par BICI Bourse.
/// Conçu pour être résilient : ne lance jamais d'erreur bloquante mais
/// émet des alertes pour signaler les champs à compléter.
class BiciBourseOrderParser {
  static final _reNumero =
      RegExp(r'ORDRE D.ACHAT N.[ ]*([0-9]+)', caseSensitive: false);
  static final _reTitre = RegExp(
      r'([A-Z0-9]{2,6})[ ]*-[ ]*([A-Z]{2}[A-Z0-9]{9}[0-9])[ ]*-[ ]*(.+)');
  static final _reQte = RegExp(
      r'ordre d.(?:Acheter|Vendre)[\s_:.\-]*([0-9]+)',
      caseSensitive: false);
  static final _reValidite = RegExp(
      r'Validit.*jusqu.au[ ]*:?[ ]*([0-9]{2}/[0-9]{2}/[0-9]{4})',
      caseSensitive: false);
  static final _reRecuDate = RegExp(
      r'Ordre re.u le[ ]*:?[ ]*([0-9]{2}/[0-9]{2}/[0-9]{4})',
      caseSensitive: false);
  static final _reRecuHeure = RegExp(
      r'Ordre re.u .[ ]*:?[ ]*([0-9]{2}:[0-9]{2}:[0-9]{2})|Le [0-9]{2}/[0-9]{2}/[0-9]{4} .[ ]*([0-9]{2}:[0-9]{2}:[0-9]{2})',
      caseSensitive: false);
  static final _reCours = RegExp(
      r'Cours[ ]*:[ ]*([A-Za-zÀ-ÿ ]+?)[ ]*([0-9][0-9 .,]*)?$',
      caseSensitive: false,
      multiLine: true);

  /// Parse les lignes extraites pour en déduire un ordre d'achat structuré.
  static ParsedOrder parse(List<PdfLine> lines) {
    final alertes = <Alerte>[];
    String? numeroOrdre;
    int? quantite;
    String? codeTitre, isin, libelle;
    TypeCours typeCours = TypeCours.autre;
    int? prixLimite;
    DateTime? dateValidite, recuLe;
    String? recuLeDate;
    String? recuLeHeure;

    final fullText = lines.map((l) => l.text).join('\n');

    // 1. Numéro d'ordre
    final mNumero = _reNumero.firstMatch(fullText);
    if (mNumero != null) {
      numeroOrdre = mNumero.group(1);
    } else {
      alertes.add(const Alerte(
        code: 'E_CHAMP_MANQUANT',
        severite: Severite.alerte,
        message: 'Numéro d\'ordre non trouvé.',
      ));
    }

    // 2. Référencement du titre (Code - ISIN - Libellé)
    final mTitre = _reTitre.firstMatch(fullText);
    if (mTitre != null) {
      codeTitre = mTitre.group(1)?.trim();
      isin = mTitre.group(2)?.trim();
      libelle = mTitre.group(3)?.trim();
    } else {
      alertes.add(const Alerte(
        code: 'E_CHAMP_MANQUANT',
        severite: Severite.alerte,
        message: 'Titre (code / ISIN) non identifié.',
      ));
    }

    // 3. Quantité
    final mQte = _reQte.firstMatch(fullText);
    if (mQte != null) {
      quantite = int.tryParse(mQte.group(1)!);
    } else {
      alertes.add(const Alerte(
        code: 'E_CHAMP_MANQUANT',
        severite: Severite.bloquant,
        message: 'Quantité non trouvée.',
      ));
    }

    // 4. Modalité de cours (ex: LIMITE 8,700)
    final mCours = _reCours.firstMatch(fullText);
    if (mCours != null) {
      final typeRaw = mCours.group(1)?.trim().toUpperCase() ?? '';
      if (typeRaw.contains('LIMITE')) {
        typeCours = TypeCours.limite;
      } else {
        typeCours = TypeCours.autre;
        alertes.add(Alerte(
          code: 'W_TYPE_COURS_INCONNU',
          severite: Severite.alerte,
          message: 'Type de cours "$typeRaw" non reconnu.',
        ));
      }
      final prixRaw = mCours.group(2);
      if (prixRaw != null) {
        prixLimite = parseFcfa(prixRaw);
        if (prixLimite == null) {
          alertes.add(Alerte(
            code: 'W_PRIX_ILLISIBLE',
            severite: Severite.alerte,
            message: 'Prix "$prixRaw" non interprétable.',
          ));
        }
      }
    }

    // 5. Validité
    final mValidite = _reValidite.firstMatch(fullText);
    if (mValidite != null) {
      dateValidite = parseDateFr(mValidite.group(1)!);
    }

    // 6. Horodatage de réception
    final mRecuDate = _reRecuDate.firstMatch(fullText);
    if (mRecuDate != null) {
      recuLeDate = mRecuDate.group(1);
    }
    final mRecuHeure = _reRecuHeure.firstMatch(fullText);
    if (mRecuHeure != null) {
      recuLeHeure = mRecuHeure.group(1) ?? mRecuHeure.group(2);
    }

    if (recuLeDate != null) {
      final d = parseDateFr(recuLeDate);
      if (d != null && recuLeHeure != null) {
        final parts = recuLeHeure.split(':');
        if (parts.length == 3) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final s = int.tryParse(parts[2]) ?? 0;
          recuLe = DateTime.utc(d.year, d.month, d.day, h, m, s);
        } else {
          recuLe = d;
        }
      } else {
        recuLe = d;
      }
    }

    // Alerte générale si des données indispensables manquent
    if (numeroOrdre == null ||
        quantite == null ||
        codeTitre == null ||
        prixLimite == null ||
        dateValidite == null ||
        recuLe == null) {
      alertes.add(const Alerte(
        code: 'I_EXTRACTION_PARTIELLE',
        severite: Severite.info,
        message: 'Certains champs n\'ont pas pu être lus.',
      ));
    }

    return ParsedOrder(
      sgi: 'BICI BOURSE',
      sgiSlug: 'bici_bourse',
      numeroOrdre: numeroOrdre,
      sens: Sens.achat,
      quantite: quantite,
      codeTitre: codeTitre,
      isin: isin,
      libelle: libelle,
      typeCours: typeCours,
      prixLimite: prixLimite,
      dateValidite: dateValidite,
      recuLe: recuLe,
      alertes: alertes,
    );
  }
}
