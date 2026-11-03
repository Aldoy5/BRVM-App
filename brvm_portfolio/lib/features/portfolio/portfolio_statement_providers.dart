import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/portfolio_statement_repository.dart';
import '../auth/auth_providers.dart';
import '../pdf_import/data/bici_portfolio_statement_parser.dart';

final portfolioStatementRepositoryProvider = Provider((ref) =>
    PortfolioStatementRepository(userId: ref.watch(currentUserIdProvider)));

class PortfolioStatementNotifier extends Notifier<SavedPortfolioStatement?> {
  StreamSubscription<SavedPortfolioStatement?>? _subscription;
  @override
  SavedPortfolioStatement? build() {
    ref.onDispose(() => _subscription?.cancel());
    _subscription?.cancel();
    _subscription = ref.watch(portfolioStatementRepositoryProvider).watch().listen((value) => state = value);
    return null;
  }

  Future<void> save(SavedPortfolioStatement statement) =>
      ref.read(portfolioStatementRepositoryProvider).save(statement);
}

final portfolioStatementProvider = NotifierProvider<PortfolioStatementNotifier, SavedPortfolioStatement?>(PortfolioStatementNotifier.new);
