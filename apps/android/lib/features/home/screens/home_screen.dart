import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/menu_card.dart';
import '../../../shared/widgets/summary_row.dart';

/// Home screen — the landing page of the application.
///
/// Visual redesign: cleaner top bar, larger greeting typography,
/// increased whitespace, lighter card surfaces.
/// Layout and navigation unchanged.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Light neutral background — not white, not grey
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        // White app bar — green is accent only
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Mr Squirrel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header — larger, more human
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mau mengerjakan apa hari ini?',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu cards
              _buildMenuGrid(context),

              const SizedBox(height: 28),

              // Today's summary section
              _TodaySummary(),

              // Bottom breathing room
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return Column(
      children: [
        MenuCard(
          icon: Icons.calculate_rounded,
          title: 'Hitung Penjualan',
          description:
              'Mencatat penjualan dan menghitung total belanja pelanggan.',
          onTap: () => context.push('/penjualan'),
        ),
        const SizedBox(height: 12),
        MenuCard(
          icon: Icons.shopping_bag_rounded,
          title: 'Belanja / Restock',
          description: 'Menambahkan stok setelah selesai berbelanja.',
          onTap: () => context.push('/restock'),
        ),
        const SizedBox(height: 12),
        MenuCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Kasbon',
          description: 'Mencatat pelanggan yang masih memiliki hutang.',
          onTap: () => context.push('/kasbon'),
        ),
        const SizedBox(height: 12),
        MenuCard(
          icon: Icons.inventory_2_rounded,
          title: 'Produk',
          description: 'Kelola daftar produk dan harga.',
          onTap: () => context.push('/produk'),
        ),

        // DEV ONLY — completely hidden in release builds.
        // kDebugMode is a compile-time constant; Dart tree-shaker
        // eliminates this entire block (including the import) in
        // --release mode.
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          _DevToolsCard(),
        ],
      ],
    );
  }
}

/// DEV ONLY card — not rendered in release builds.
class _DevToolsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.deepOrange[50],
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/dev-tools'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.developer_mode_rounded,
                  size: 26,
                  color: Colors.deepOrange[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Developer Tools',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEBUG',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Stats, generators, integrity checks, danger zone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepOrange[900]?.withAlpha(160),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.deepOrange[300],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's summary card — static placeholder.
/// Will become dynamic in a later phase.
class _TodaySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Ringkasan Hari Ini',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              SummaryRow(label: 'Penjualan', value: 'Rp0'),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 14),
              SummaryRow(label: 'Transaksi', value: '0'),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 14),
              SummaryRow(label: 'Kasbon Aktif', value: '0'),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 14),
              SummaryRow(
                label: 'Sinkronisasi',
                value: 'Belum tersedia',
                valueColor: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
