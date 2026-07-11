import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/exports/screens/exports_screen.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/admin/screens/admin_sub_screens.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/overview/screens/overview_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/customers/screens/customer_detail_screen.dart';
import '../features/restocks/screens/restocks_screen.dart';
import '../features/restocks/screens/restock_detail_screen.dart';
import '../features/sales/screens/sales_screen.dart';
import '../features/sales/screens/sale_detail_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../shared/widgets/shared_widgets.dart';
import '../shared/layout/app_scaffold.dart';

/// Global router key — allows redirect to work across the tree.
final _routerKey = GlobalKey<NavigatorState>();

/// A Riverpod-aware GoRouter.
///
/// Auth guard: every route except /login requires an active session.
/// Unauthenticated users are always redirected to /login.
/// After login they are sent to /overview.
GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/overview',
    redirect: (context, state) {
      final session =
          Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/overview';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final titles = {
            '/overview': 'Overview',
            '/products': 'Products',
            '/sales': 'Sales',
            '/restocks': 'Restocks',
            '/customers': 'Customers',
            '/analytics': 'Analytics',
            '/exports': 'Export Center',
            '/backup': 'Backup & Recovery',
            '/admin': 'Administration',
            '/users': 'Users',
            '/settings': 'Settings',
          };
          final path = state.matchedLocation;
          final baseKey = '/' + path.split('/')[1];
          final title = titles[baseKey] ?? 'Dashboard';
          return AppScaffold(
            title: title,
            breadcrumb: 'MR SQUIRREL / $title',
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/overview',
            builder: (_, __) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (_, __) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => _ComingSoonPage(
                    title: 'Product ${state.pathParameters['id']}'),
              ),
            ],
          ),
          GoRoute(
            path: '/sales',
            builder: (_, __) => const SalesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => SaleDetailScreen(
                    saleId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/restocks',
            builder: (_, __) => const RestocksScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => RestockDetailScreen(
                    restockId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            builder: (_, __) => const CustomersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => CustomerDetailScreen(
                    customerId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/backup',
            builder: (_, __) => const BackupScreen(),
          ),
          GoRoute(
            path: '/exports',
            builder: (_, __) => const ExportsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminScreen(),
            routes: [
              GoRoute(path: 'users', builder: (_, __) => const AdminUsersScreen()),
              GoRoute(path: 'devices', builder: (_, __) => const AdminDevicesScreen()),
              GoRoute(path: 'sync', builder: (_, __) => const AdminSyncScreen()),
              GoRoute(path: 'organization', builder: (_, __) => const AdminOrganizationScreen()),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (_, __) => const UsersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => _NotFoundPage(error: state.error),
  );
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        title: title,
        description: 'Detail view coming in a future phase.',
        icon: Icons.construction_rounded,
      ),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 72, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Page not found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/overview'),
              child: const Text('Back to Overview'),
            ),
          ],
        ),
      ),
    );
  }
}
