import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/product/screens/product_list_screen.dart';
import '../../features/product/screens/product_form_screen.dart';
import '../../features/penjualan/screens/penjualan_screen.dart';
import '../../features/restock/screens/restock_screen.dart';
import '../../features/kasbon/screens/customer_list_screen.dart';
import '../../features/kasbon/screens/customer_detail_screen.dart';
import '../../features/kasbon/screens/customer_form_screen.dart';
import '../../features/kasbon/screens/kasbon_entry_screens.dart';
// DEV ONLY — tree-shaken out of release builds
import '../../features/dev_tools/screens/dev_tools_screen.dart';

/// Application router.
///
/// Phase 1: Product admin screens (dev tooling)
/// Phase 2: Hitung Penjualan
/// Phase 3: Home screen, navigation shell
/// Phase 4: Belanja / Restock
/// Phase 5: Kasbon (Pelanggan & hutang)
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/penjualan',
      name: 'penjualan',
      builder: (context, state) => const PenjualanScreen(),
    ),
    GoRoute(
      path: '/restock',
      name: 'restock',
      builder: (context, state) => const RestockScreen(),
    ),
    GoRoute(
      path: '/produk',
      name: 'product-list',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/produk/tambah',
      name: 'product-add',
      builder: (context, state) => const ProductFormScreen(),
    ),
    GoRoute(
      path: '/produk/edit/:id',
      name: 'product-edit',
      builder: (context, state) => ProductFormScreen(
        productId: state.pathParameters['id'],
      ),
    ),
    // Kasbon routes
    GoRoute(
      path: '/kasbon',
      name: 'kasbon',
      builder: (context, state) => const CustomerListScreen(),
    ),
    GoRoute(
      path: '/kasbon/tambah',
      name: 'customer-add',
      builder: (context, state) => const CustomerFormScreen(),
    ),
    GoRoute(
      path: '/kasbon/:id',
      name: 'customer-detail',
      builder: (context, state) => CustomerDetailScreen(
        customerId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/kasbon/:id/edit',
      name: 'customer-edit',
      builder: (context, state) => CustomerFormScreen(
        customerId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/kasbon/:id/hutang',
      name: 'record-debt',
      builder: (context, state) => RecordDebtScreen(
        customerId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/kasbon/:id/bayar',
      name: 'record-payment',
      builder: (context, state) => RecordPaymentScreen(
        customerId: state.pathParameters['id']!,
      ),
    ),
    // DEV ONLY — /dev-tools route is only registered in debug mode.
    // In release builds, kDebugMode is false and this block is
    // completely eliminated by the Dart tree-shaker.
    if (kDebugMode)
      GoRoute(
        path: '/dev-tools',
        name: 'dev-tools',
        builder: (context, state) => const DevToolsScreen(),
      ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Halaman tidak ditemukan: ${state.error}'),
    ),
  ),
);
