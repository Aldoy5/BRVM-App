import 'pdf_line_builder.dart';
import 'pdf_text_extractor.dart';

class BiciStatementHolding {
  final String code;
  final String isin;
  final String name;
  final int quantity;
  final int costPrice;
  final int marketPrice;

  const BiciStatementHolding({
    required this.code,
    required this.isin,
    required this.name,
    required this.quantity,
    required this.costPrice,
    required this.marketPrice,
  });

  BiciStatementHolding copyWith({String? code, int? quantity, int? costPrice}) =>
      BiciStatementHolding(
        code: code ?? this.code,
        isin: isin,
        name: name,
        quantity: quantity ?? this.quantity,
        costPrice: costPrice ?? this.costPrice,
        marketPrice: marketPrice,
      );
}

class BiciPortfolioStatement {
  final DateTime date;
  final List<BiciStatementHolding> holdings;
  const BiciPortfolioStatement(this.date, this.holdings);
}

/// Parser du relevé de compte titres BICI Bourse (format JasperReports).
class BiciPortfolioStatementParser {
  static final _isin = RegExp(r'\b([A-Z]{2}[A-Z0-9]{10})\b');
  static final _date = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b');
  static final _amount = RegExp(r'^\d[\d,.]*$');

  static BiciPortfolioStatement? parse(List<PdfLine> lines) {
    final text = lines.map((line) => line.text).join(' ').toUpperCase();
    if (!text.contains('RELEVE DE COMPTE TITRES') ||
        !text.contains('BICI BOURSE')) return null;

    final dateMatch = RegExp(r'RELEVE DE COMPTE TITRES\s+DU\s*:?\s*(\d{2}/\d{2}/\d{4})')
        .firstMatch(text);
    final date = dateMatch == null ? null : _parseDate(dateMatch.group(1)!);
    if (date == null) return null;

    final holdings = <BiciStatementHolding>[];
    for (final line in lines) {
      final isinMatch = _isin.firstMatch(line.text.toUpperCase());
      if (isinMatch == null) continue;
      final code = line.text.substring(0, isinMatch.start).trim().split(RegExp(r'\s+')).last;
      if (!RegExp(r'^[A-Z0-9]{2,6}$').hasMatch(code)) continue;
      final tail = line.text.substring(isinMatch.end);
      final dateInRow = _date.firstMatch(tail);
      if (dateInRow == null) continue;
      final beforeDate = tail.substring(0, dateInRow.start);
      final availability = RegExp(r'DENOU[EÉ]E', caseSensitive: false).firstMatch(beforeDate);
      if (availability == null) continue;

      final name = beforeDate.substring(0, availability.start).trim();
      final numericTokens = beforeDate.substring(availability.end)
          .split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      final parsed = _parseQuantityAndCost(numericTokens);
      if (name.isEmpty || parsed == null) continue;

      holdings.add(BiciStatementHolding(
        code: code,
        isin: isinMatch.group(1)!,
        name: name,
        quantity: parsed.$1,
        costPrice: parsed.$2,
        marketPrice: parsed.$3,
      ));
    }
    if (holdings.isEmpty) return null;
    return BiciPortfolioStatement(date, holdings);
  }

  static (int, int, int)? _parseQuantityAndCost(List<String> tokens) {
    final values = <int>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i].replaceAll(',', '');
      if (!_amount.hasMatch(token)) continue;
      final value = int.tryParse(token.replaceAll('.', ''));
      if (value == null) continue;
      // Les milliers peuvent être séparés en deux mots dans certains extracteurs.
      if (i + 1 < tokens.length && RegExp(r'^\d{3}$').hasMatch(tokens[i + 1])) {
        final combined = int.tryParse('$token${tokens[i + 1]}'.replaceAll('.', ''));
        if (combined != null && value < 1000) {
          values.add(combined);
          i++;
          continue;
        }
      }
      values.add(value);
    }
    if (values.length < 3) return null;
    return (values[0], values[1], values[2]);
  }

  static DateTime? _parseDate(String raw) {
    final p = raw.split('/');
    final d = DateTime.utc(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    return d.day == int.parse(p[0]) && d.month == int.parse(p[1]) ? d : null;
  }
}
