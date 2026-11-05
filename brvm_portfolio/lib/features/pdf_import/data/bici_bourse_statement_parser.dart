import 'dart:typed_data';
import '../../../core/models/operation.dart';
import 'syncfusion_pdf_extractor.dart';

/// Résultat de l'analyse d'un relevé de compte BICI Bourse.
class StatementParseResult {
  /// Numéro de compte titre extrait.
  final String? numeroCompte;

  /// Nom du client extrait.
  final String? nomClient;

  /// Date du relevé.
  final DateTime? dateReleve;

  /// Solde espèces extrait du relevé (FCFA).
  final int? soldeEspeces;

  /// Lignes d'actions parsées, prêtes à être converties en opérations.
  final List<StatementLine> lignes;

  /// Avertissements non bloquants.
  final List<String> avertissements;

  /// Erreur bloquante si le document n'est pas un relevé BICI Bourse valide.
  final String? erreurBloquante;

  const StatementParseResult({
    this.numeroCompte,
    this.nomClient,
    this.dateReleve,
    this.soldeEspeces,
    required this.lignes,
    this.avertissements = const [],
    this.erreurBloquante,
  });

  bool get estValide => erreurBloquante == null && lignes.isNotEmpty;
}

/// Une ligne de position extraite du relevé.
class StatementLine {
  final String codeTitre;
  final String isin;
  final String libelle;
  final int quantite;

  /// Prix de Revient Unitaire (extrait du relevé).
  final int prixRevient;

  /// Cours au moment du relevé.
  final int cours;

  /// Date du cours.
  final DateTime? dateCours;

  const StatementLine({
    required this.codeTitre,
    required this.isin,
    required this.libelle,
    required this.quantite,
    required this.prixRevient,
    required this.cours,
    this.dateCours,
  });

  /// Convertit cette ligne en opération d'achat pour initialiser le portefeuille
  /// avec le PRU exact du relevé.
  Operation toOperation({required DateTime dateReleve, String? notes}) {
    final id = 'import_${codeTitre}_${dateReleve.millisecondsSinceEpoch}';
    return Operation(
      id: id,
      type: OperationType.achat,
      date: dateCours ?? dateReleve,
      stockCode: codeTitre,
      stockName: libelle,
      quantity: quantite,
      unitPrice: prixRevient,
      fees: 0,
      notes: notes ?? 'Importé depuis relevé BICI Bourse du ${_formatDate(dateReleve)}',
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  String toString() =>
      'StatementLine($codeTitre / $isin : $quantite titres, PRU $prixRevient, cours $cours)';
}

/// Parseur du **Relevé de Compte Titres** BICI Bourse.
class BiciBourseStatementParser {
  static final _extractor = SyncfusionPdfTextExtractor();

  // Regex de détection
  static final _reIsin = RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$');
  static final _reCode = RegExp(r'^[A-Z0-9]{2,6}$');
  static final _reDate = RegExp(r'(\d{2}/\d{2}/\d{4})');
  static final _reDateReleve = RegExp(
    r'RELEVE DE COMPTE TITRES DU\s*:?\s*(\d{2}/\d{2}/\d{4})',
    caseSensitive: false,
  );

  /// Point d'entrée principal : parse les bytes d'un PDF et renvoie un résultat.
  static Future<StatementParseResult> parse(Uint8List bytes) async {
    final fullText = await _extractor.extractFullText(bytes);
    if (fullText.isEmpty) {
      return const StatementParseResult(
        lignes: [],
        erreurBloquante:
            'Impossible d\'extraire le texte du PDF. '
            'Vérifiez que le fichier n\'est pas scanné (image).',
      );
    }

    // Vérification du document
    final upperText = fullText.toUpperCase();
    if (!upperText.contains('RELEVE DE COMPTE TITRES') &&
        !upperText.contains('RELEVÉ DE COMPTE TITRES')) {
      return const StatementParseResult(
        lignes: [],
        erreurBloquante:
            'Ce document ne semble pas être un Relevé de Compte Titres BICI Bourse.',
      );
    }

    final avertissements = <String>[];

    // 1. Métadonnées
    DateTime? dateReleve;
    final mDate = _reDateReleve.firstMatch(fullText);
    if (mDate != null) {
      dateReleve = _parseDate(mDate.group(1)!);
    } else {
      avertissements.add('Date du relevé non trouvée.');
    }

    final lines = fullText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final metadata = _extractMetadata(lines);

    // 2. Extraction des lignes de positions
    final lignes = _parseActionLines(lines, avertissements);

    if (lignes.isEmpty) {
      avertissements.add(
        'Aucune ligne de position n\'a pu être extraite. '
        'Le format du document a peut-être changé.',
      );
    }

    return StatementParseResult(
      numeroCompte: metadata.numeroCompte,
      nomClient: metadata.nomClient,
      dateReleve: dateReleve,
      soldeEspeces: metadata.soldeEspeces,
      lignes: lignes,
      avertissements: avertissements,
    );
  }

  /// Extraction des métadonnées du compte (Client, Compte Titre, Solde espèces)
  static ({String? nomClient, String? numeroCompte, int? soldeEspeces})
      _extractMetadata(List<String> lines) {
    String? nomClient;
    String? numeroCompte;
    int? soldeEspeces;

    // Repérage dans les premières lignes du document
    for (int i = 0; i < lines.length && i < 25; i++) {
      final line = lines[i];

      // Numéro de compte titre (ex: "902501001", 9 chiffres)
      if (RegExp(r'^\d{8,11}$').hasMatch(line) && numeroCompte == null) {
        numeroCompte = line;
      }

      // Code réglementaire (20 chiffres) - à ignorer pour le compte titre
      if (RegExp(r'^\d{16,25}$').hasMatch(line)) {
        continue;
      }

      // Solde compte espèce (ex: "9 347")
      if (soldeEspeces == null &&
          i >= 3 &&
          RegExp(r'^[\d\s]+$').hasMatch(line)) {
        final val = _parseInt(line);
        if (val != null && val < 100000000 && val != _parseInt(numeroCompte ?? '')) {
          soldeEspeces = val;
        }
      }

      // Nom client : première ligne majuscule après "RELEVE DE COMPTE..."
      if (nomClient == null &&
          i >= 1 &&
          i <= 5 &&
          !line.toUpperCase().contains('RELEVE') &&
          !line.toUpperCase().contains('COMPTE') &&
          RegExp(r'^[A-ZÀ-ÿ\s\-]{4,}$').hasMatch(line)) {
        nomClient = line;
      }
    }

    return (
      nomClient: nomClient,
      numeroCompte: numeroCompte,
      soldeEspeces: soldeEspeces,
    );
  }

  /// Extraction des lignes d'actions
  static List<StatementLine> _parseActionLines(
    List<String> lines,
    List<String> avertissements,
  ) {
    final positions = <StatementLine>[];

    // Localiser tous les index où se trouve un code ISIN
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_reIsin.hasMatch(line)) continue;

      final isin = line;

      String? codeValeur;
      int? cours;
      DateTime? dateCours;
      int? prixRevient;
      String? description;
      int? quantite;

      // 1. Code valeur : chercher au-dessus de l'ISIN (dans les 3 lignes précédentes)
      for (int k = i - 1; k >= (i - 3).clamp(0, lines.length); k--) {
        final cand = lines[k].trim();
        if (_reCode.hasMatch(cand) && !_isNumeric(cand)) {
          codeValeur = cand;
          break;
        }
      }

      // 2. Cours : ligne numérique juste avant l'ISIN
      if (i > 0) {
        cours = _parseInt(lines[i - 1]);
      }

      // 3. Date du cours : ligne juste après l'ISIN
      if (i + 1 < lines.length && _reDate.hasMatch(lines[i + 1])) {
        final m = _reDate.firstMatch(lines[i + 1]);
        if (m != null) dateCours = _parseDate(m.group(1)!);
      }

      // 4. Prix de revient : à i + 2
      if (i + 2 < lines.length) {
        prixRevient = _parseInt(lines[i + 2]);
      }

      // 5. Description : à i + 3
      if (i + 3 < lines.length) {
        description = lines[i + 3].trim();
      }

      // 6. Quantité : chercher après la mention "DENOUEE" ou à i + 5
      for (int k = i + 3; k <= (i + 7).clamp(0, lines.length - 1); k++) {
        final cand = lines[k].toUpperCase();
        if (cand.contains('DENOUEE') || cand.contains('DÉNOUÉE')) {
          if (k + 1 < lines.length) {
            quantite = _parseQuantity(lines[k + 1]);
            break;
          }
        }
      }

      // Fallback quantité à i + 5 si non trouvée
      quantite ??= (i + 5 < lines.length) ? _parseQuantity(lines[i + 5]) : null;

      codeValeur ??= isin.substring(0, 4);
      description ??= codeValeur;

      if (quantite != null && prixRevient != null && quantite > 0 && prixRevient > 0) {
        positions.add(StatementLine(
          codeTitre: codeValeur,
          isin: isin,
          libelle: description,
          quantite: quantite,
          prixRevient: prixRevient,
          cours: cours ?? prixRevient,
          dateCours: dateCours,
        ));
      } else {
        avertissements.add(
          'Ligne ISIN $isin ($codeValeur) : données incomplètes (Qte: $quantite, PRU: $prixRevient).',
        );
      }
    }

    return positions;
  }

  // ─── Utilitaires ───────────────────────────────────────────────────────────

  static bool _isNumeric(String s) {
    final cleaned = s.replaceAll(' ', '').replaceAll(',', '').replaceAll('.', '');
    return int.tryParse(cleaned) != null;
  }

  static int? _parseInt(String raw) {
    final cleaned = raw
        .replaceAll('\u00a0', '')
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .trim();
    return int.tryParse(cleaned);
  }

  /// Parse une quantité d'actions qui peut être "3", "3,000", "3 000", etc.
  static int? _parseQuantity(String raw) {
    final trimmed = raw.trim();
    final cleaned = trimmed
        .replaceAll('\u00a0', '')
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll('.', '');
    return int.tryParse(cleaned);
  }

  static DateTime? _parseDate(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }
}
