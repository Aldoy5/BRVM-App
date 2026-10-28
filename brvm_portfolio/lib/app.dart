import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/responsive.dart';
import 'core/constants.dart';
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
                routes: [
                  GoRoute(
                    path: 'stock/:code',
                    builder: (context, state) {
                      final code = state.pathParameters['code'] ?? '';
                      return StockDetailScreen(stockCode: code);
                    },
                  ),
                ],
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

      // Redirection /stock/:code vers /market/stock/:code pour conserver la barre de navigation
      GoRoute(
        path: '/stock/:code',
        redirect: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return '/market/stock/$code';
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

/// Scaffold englobant avec BottomAppBar minimaliste et FAB central "+"
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

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return InkWell(
      onTap: () => _onDestinationSelected(index),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      // Layout desktop : NavigationRail à gauche + contenu centré
      return Scaffold(
        body: Row(
          children: [
            // Rail de navigation latéral
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: Colors.white,
              extended: MediaQuery.sizeOf(context).width >= 1100,
              minWidth: 72,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FloatingActionButton(
                  onPressed: () => context.push('/operation/add'),
                  elevation: 2,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Portefeuille'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart),
                  label: Text('Marché'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('Historique'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 0.8, color: AppColors.border),
            // Contenu principal centré
            Expanded(
              child: navigationShell,
            ),
          ],
        ),
      );
    }

    // Layout mobile : Bottom navigation bar
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildNavItem(
                    context: context,
                    index: 0,
                    label: 'Portefeuille',
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildNavItem(
                    context: context,
                    index: 1,
                    label: 'Marché',
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/operation/add'),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF237A4B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildNavItem(
                    context: context,
                    index: 2,
                    label: 'Historique',
                  ),
                ),
              ],
            ),
          ),
        ),
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
