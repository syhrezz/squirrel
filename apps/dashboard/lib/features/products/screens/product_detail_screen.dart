import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../providers/product_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(productDetailProvider(productId));

    return detailAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(productDetailProvider(productId)),
      ),
      data: (product) => SingleChildScrollView(
        padding: const EdgeInsets.all(DashboardTheme.sp32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/products'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PageHeader(
                    title: product.name,
                    subtitle: product.category,
                  ),
                ),
                StatusChip(
                  label: product.isActive
                      ? 'Aktif'
                      : 'Nonaktif',
                  color: product.isActive
                      ? DashboardTheme.success
                      : DashboardTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 1: Product Info + Inventory
            LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Informasi Produk',
                        child: Column(
                          children: [
                            _InfoRow('Nama', product.name),
                            _InfoRow(
                                'Kategori', product.category),
                            _InfoRow(
                                'Status',
                                product.isActive
                                    ? 'Aktif'
                                    : 'Nonaktif'),
                            _InfoRow('Unit Stok',
                                product.inventoryUnit),
                            _InfoRow('Unit Beli',
                                product.purchaseUnit),
                            _InfoRow('Konversi',
                                product.formattedConversion),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Inventori Saat Ini',
                        child: Column(
                          children: [
                            _InfoRow('Stok',
                                product.formattedStock,
                                valueStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: product.currentStock <=
                                          0
                                      ? DashboardTheme.danger
                                      : product.currentStock <=
                                              3
                                          ? DashboardTheme
                                              .warning
                                          : DashboardTheme
                                              .textPrimary,
                                )),
                            _InfoRow('Nilai Inventori',
                                product.formattedValue),
                            _InfoRow(
                              'Restock Terakhir',
                              product.lastRestockDate != null
                                  ? DateFormat('d MMM yyyy')
                                      .format(product
                                          .lastRestockDate!)
                                  : '—',
                            ),
                            _InfoRow(
                              'Penjualan Terakhir',
                              product.lastSaleDate != null
                                  ? DateFormat('d MMM yyyy')
                                      .format(
                                          product.lastSaleDate!)
                                  : '—',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Row 2: Pricing + Sales 30d
            LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Harga',
                        child: Column(
                          children: [
                            _InfoRow('Harga Jual',
                                product.formattedSell,
                                valueStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        DashboardTheme.primary)),
                            _InfoRow('Harga Beli Terakhir',
                                product.formattedBuy),
                            _InfoRow('Estimasi Margin',
                                product.formattedMargin),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Ringkasan Penjualan',
                        subtitle: '30 hari terakhir',
                        child: Column(
                          children: [
                            _InfoRow('Unit Terjual',
                                '${product.unitsSold30d} ${product.inventoryUnit}'),
                            _InfoRow('Pendapatan',
                                product.formattedRevenue30d),
                            _InfoRow(
                              'Rata-rata Harian',
                              '${product.avgDailySales30d.toStringAsFixed(1)} ${product.inventoryUnit}/hari',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Selling options
            if (product.sellingOptions.isNotEmpty)
              SectionCard(
                title: 'Opsi Jual',
                subtitle: '${product.sellingOptions.length} opsi',
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                            child: _ColumnHeader('Nama')),
                        const SizedBox(
                            width: 100,
                            child: _ColumnHeader('Qty',
                                textAlign:
                                    TextAlign.right)),
                        const SizedBox(
                            width: 130,
                            child: _ColumnHeader('Harga',
                                textAlign:
                                    TextAlign.right)),
                      ],
                    ),
                    Divider(
                        height: 1,
                        color: DashboardTheme.border),
                    ...product.sellingOptions.map((o) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(o.displayName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500))),
                            SizedBox(
                              width: 100,
                              child: Text(
                                  '${o.quantity} ${product.inventoryUnit}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 13)),
                            ),
                            SizedBox(
                              width: 130,
                              child: Text(o.formattedPrice,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: DashboardTheme
                                          .primary)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Row 3: Recent sales + Recent restocks
            LayoutBuilder(
              builder: (context, constraints) {
                final side = (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: _RecentSalesCard(
                          productId: productId),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: _RecentRestocksCard(
                          productId: productId),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Inventory timeline chart
            _InventoryTimelineCard(productId: productId),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Sales card
// ---------------------------------------------------------------------------

class _RecentSalesCard extends ConsumerWidget {
  const _RecentSalesCard({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync =
        ref.watch(productRecentSalesProvider(productId));

    return SectionCard(
      title: 'Penjualan Terakhir',
      subtitle: '20 transaksi',
      child: salesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) =>
            ErrorView(message: e.toString()),
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              title: 'Belum ada penjualan',
              description: 'Produk ini belum pernah terjual.',
              icon: Icons.receipt_long_rounded,
            );
          }
          return Column(
            children: [
              Row(
                children: const [
                  Expanded(child: _ColumnHeader('Tanggal')),
                  SizedBox(
                      width: 60,
                      child: _ColumnHeader('Qty',
                          textAlign: TextAlign.right)),
                  SizedBox(
                      width: 100,
                      child: _ColumnHeader('Total',
                          textAlign: TextAlign.right)),
                ],
              ),
              Divider(height: 1, color: DashboardTheme.border),
              ...sales.map((s) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(s.formattedDate,
                                style: const TextStyle(
                                    fontSize: 12))),
                        SizedBox(
                          width: 60,
                          child: Text('${s.quantity}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12)),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(s.formattedSubtotal,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      DashboardTheme.primary)),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Restocks card
// ---------------------------------------------------------------------------

class _RecentRestocksCard extends ConsumerWidget {
  const _RecentRestocksCard({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restocksAsync =
        ref.watch(productRecentRestocksProvider(productId));

    return SectionCard(
      title: 'Restock Terakhir',
      subtitle: '20 pengiriman',
      child: restocksAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) =>
            ErrorView(message: e.toString()),
        data: (restocks) {
          if (restocks.isEmpty) {
            return const EmptyState(
              title: 'Belum ada restock',
              description: 'Produk ini belum pernah direstock.',
              icon: Icons.shopping_bag_rounded,
            );
          }
          return Column(
            children: [
              Row(
                children: const [
                  Expanded(child: _ColumnHeader('Tanggal')),
                  SizedBox(
                      width: 60,
                      child: _ColumnHeader('Qty',
                          textAlign: TextAlign.right)),
                  SizedBox(
                      width: 100,
                      child: _ColumnHeader('Harga Beli',
                          textAlign: TextAlign.right)),
                ],
              ),
              Divider(height: 1, color: DashboardTheme.border),
              ...restocks.map((r) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(r.formattedDate,
                                style: const TextStyle(
                                    fontSize: 12))),
                        SizedBox(
                          width: 60,
                          child: Text('${r.quantity}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12)),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(r.formattedPrice,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory Timeline chart
// ---------------------------------------------------------------------------

class _InventoryTimelineCard extends ConsumerWidget {
  const _InventoryTimelineCard({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync =
        ref.watch(productInventoryTimelineProvider(productId));

    return SectionCard(
      title: 'Pergerakan Stok',
      subtitle: '90 hari terakhir',
      child: timelineAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (points) {
          if (points.isEmpty) {
            return const SizedBox(
              height: 200,
              child: EmptyState(
                title: 'Belum ada pergerakan stok',
                description:
                    'Data akan muncul setelah ada transaksi.',
                icon: Icons.show_chart_rounded,
              ),
            );
          }
          return SizedBox(
            height: 200,
            child: _StockLineChart(points: points),
          );
        },
      ),
    );
  }
}

class _StockLineChart extends StatelessWidget {
  const _StockLineChart({required this.points});
  final List points;

  @override
  Widget build(BuildContext context) {
    final stocks = points
        .map((p) => (p.stock as int).toDouble())
        .toList();
    final maxY = stocks.fold<double>(
        0, (a, b) => a > b ? a : b);

    final spots = points.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), (e.value.stock as int).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: DashboardTheme.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: TextStyle(
                    fontSize: 10,
                    color: DashboardTheme.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (points.length / 6).ceil().toDouble(),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < points.length) {
                  return Text(
                    points[idx].label as String,
                    style: TextStyle(
                        fontSize: 10,
                        color: DashboardTheme.textTertiary),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: (maxY * 1.2).clamp(1, double.infinity),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: DashboardTheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: DashboardTheme.primary.withAlpha(20),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: DashboardTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: valueStyle ??
                    const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label,
      {this.textAlign = TextAlign.left});
  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        textAlign: textAlign,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DashboardTheme.textSecondary));
  }
}
