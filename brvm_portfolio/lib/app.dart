import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'features/history/history_screen.dart';
import 'features/market/market_screen.dart';
import 'features/market/market_sync_service.dart';
import 'features/operation_form/operation_form_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/stock_detail/stock_detail_screen.dart';

// Clé de navigation globale
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Configuration principale des routes avec GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/portfolio',
    routes: [
      // Shell contenant les 3 onglets principaux et la barre de navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 1. Onglet Portefeuille (Accueil)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),

          // 2. Onglet Marché
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/market',
                builder: (context, state) => const MarketScreen(),
              ),
            ],
          ),

          // 3. Onglet Historique
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),

      // Fiche détaillée d'un titre
      GoRoute(
        path: '/stock/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return StockDetailScreen(stockCode: code);
        },
      ),

      // Formulaire d'ajout d'opération
      GoRoute(
        path: '/operation/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final stockCode = state.uri.queryParameters['stockCode'];
          final type = state.uri.queryParameters['type'];
          return OperationFormScreen(
            initialStockCode: stockCode,
            initialType: type,
          );
        },
      ),

      // Formulaire de modification d'opération existante
      GoRoute(
        path: '/operation/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return OperationFormScreen(operationId: id);
        },
      ),
    ],
  );
});

/// Scaffold englobant avec NavigationBar Material 3 et FAB "+"
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/operation/add');
        },
        tooltip: 'Ajouter une opération',
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portefeuille',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.trending_up_rounded),
            label: 'Marché',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Historique',
          ),
        ],
      ),
    );
  }
}

/// Widget racine de l'application BRVM Portfolio
class BrvmPortfolioApp extends ConsumerWidget {
  const BrvmPortfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active le service de synchronisation continue en arrière-plan
    ref.watch(marketSyncServiceProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BRVM Portfolio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('fr'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
