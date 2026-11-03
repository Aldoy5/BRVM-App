import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/pdf_import/data/bici_portfolio_statement_parser.dart';

class SavedPortfolioStatement {
  final DateTime date;
  final bool merge;
  final List<BiciStatementHolding> holdings;
  const SavedPortfolioStatement({required this.date, required this.merge, required this.holdings});
}

class PortfolioStatementRepository {
  final FirebaseFirestore? firestore;
  final String? userId;
  PortfolioStatementRepository({this.firestore, this.userId});

  DocumentReference<Map<String, dynamic>>? get _ref {
    final db = firestore ?? FirebaseFirestore.instance;
    if (userId == null) return null;
    return db.collection('users').doc(userId).collection('portfolioSnapshots').doc('latest');
  }

  Stream<SavedPortfolioStatement?> watch() {
    final ref = _ref;
    if (ref == null) return Stream.value(null);
    return ref.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      final rawDate = data['date'];
      final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.tryParse('$rawDate');
      final rows = data['holdings'];
      if (date == null || rows is! List) return null;
      return SavedPortfolioStatement(
        date: date,
        merge: data['merge'] == true,
        holdings: rows.whereType<Map>().map((row) => BiciStatementHolding(
          code: row['code'] as String,
          isin: row['isin'] as String,
          name: row['name'] as String,
          quantity: (row['quantity'] as num).toInt(),
          costPrice: (row['costPrice'] as num).toInt(),
          marketPrice: (row['marketPrice'] as num).toInt(),
        )).toList(),
      );
    });
  }

  Future<void> save(SavedPortfolioStatement statement) async {
    final ref = _ref;
    if (ref == null) throw StateError('Utilisateur non connecté');
    await ref.set({
      'date': Timestamp.fromDate(statement.date),
      'merge': statement.merge,
      'holdings': statement.holdings.map((h) => {
        'code': h.code, 'isin': h.isin, 'name': h.name,
        'quantity': h.quantity, 'costPrice': h.costPrice, 'marketPrice': h.marketPrice,
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
