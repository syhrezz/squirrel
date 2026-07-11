import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/restock_models.dart';
import '../providers/restock_providers.dart';

class RestockDetailScreen extends ConsumerWidget {
  const RestockDetailScreen(
      {super.key, required this.restockId});
  final String restockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(restockDetailProvider(restockId));

    return detailAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(restockDetailProvider(restockId)),
      ),
      data: (restock) => SingleChildScrollView(
        padding: const EdgeInsets.all(DashboardTheme.sp32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () =>
                      context.go('/restocks'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PageHeader(
                    title: restock.restockNumber,
                    subtitle:
                        '${restock.formattedDate} pukul ${restock.formattedTime}',
                  ),
                ),
                StatusChip(
                  label: restock.synced
                      ? 'Synced'
                      : 'Pending Sync',
                  color: restock.synced
                      ? DashboardTheme.success
                      : DashboardTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info + Summary row
            LayoutBuilder(
              builder: (context, constraints) {
                final side =
                    (constraints.maxWidth - 16) / 2;
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Informasi Transaksi',
                        child: Column(children: [
                          _InfoRow('Nomor Restock',
                              restock.restockNumber),
                          _InfoRow('Tanggal',
                              restock.formattedDate),
                          _InfoRow('Jam',
                              restock.formattedTime),
                          _InfoRow('Dibuat Oleh',
                              restock.createdBy),
                          _InfoRow('Device',
                              restock.deviceId),
                          _InfoRow(
                            'Sync',
                            restock.synced
                                ? 'Tersinkronisasi'
                                : 'Menunggu',
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: side,
                      child: SectionCard(
                        title: 'Ringkasan',
                        child: Column(children: [
                          _InfoRow('Jumlah Produk',
                              '${restock.items.length}'),
                          _InfoRow(
                            'Total Stok Ditambah',
                            restock.formattedInventoryAdded,
                          ),
                          _InfoRow(
                            'Total Pembelian',
                            restock.formattedTotal,
                            valueStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DashboardTheme.primary,
                            ),
                          ),
                          _InfoRow(
                            'Rata-rata/Item',
                            restock.avgCostPerItem > 0
                                ? 'Rp ${restock.avgCostPerItem.toInt()}'
                                : '—',
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Items table
            SectionCard(
              title: 'Produk Dibeli',
              subtitle: '${restock.items.length} produk',
              child: Column(
                children: [
                  // Header
                  Row(children: [
                    const Expanded(
                        child: _ColumnHeader('Produk')),
                    const SizedBox(
                        width: 80,
                        child: _ColumnHeader('Unit Beli',
                            textAlign: TextAlign.center)),
                    const SizedBox(
                        width: 80,
                        child: _ColumnHeader('Qty',
                            textAlign: TextAlign.right)),
                    const SizedBox(
                        width: 100,
                        child: _ColumnHeader('Konversi',
                            textAlign: TextAlign.center)),
                    const SizedBox(
                        width: 100,
                        child: _ColumnHeader('Stok +',
                            textAlign: TextAlign.right)),
                    const SizedBox(
                        width: 120,
                        child: _ColumnHeader('Harga Beli',
                            textAlign: TextAlign.right)),
                    const SizedBox(
                        width: 120,
                        child: _ColumnHeader('Subtotal',
                            textAlign: TextAlign.right)),
                    const SizedBox(
                        width: 32,
                        child: SizedBox.shrink()),
                  ]),
                  Divider(
                      height: 1,
                      color: DashboardTheme.border),
                  ...restock.items.map((item) =>
                      _RestockItemRow(
                          item: item, ref: null)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            SectionCard(
              title: 'Timeline',
              child: Column(children: [
                _TimelineItem(
                  icon: Icons.shopping_bag_rounded,
                  color: DashboardTheme.success,
                  title: 'Restock Dicatat',
                  subtitle:
                      '${restock.formattedDate} pukul ${restock.formattedTime} oleh ${restock.createdBy}',
                ),
                _TimelineItem(
                  icon: restock.synced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_upload_rounded,
                  color: restock.synced
                      ? DashboardTheme.primary
                      : DashboardTheme.textTertiary,
                  title: restock.synced
                      ? 'Tersinkronisasi'
                      : 'Menunggu sinkronisasi',
                  subtitle: restock.synced
                      ? 'Data telah dikirim ke server.'
                      : 'Akan dikirim saat perangkat online.',
                  isLast: true,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestockItemRow extends StatelessWidget {
  const _RestockItemRow({required this.item, this.ref});
  final RestockItemDetail item;
  final WidgetRef? ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(item.purchaseUnit,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textSecondary)),
          ),
          SizedBox(
            width: 80,
            child: Text('${item.quantity}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 100,
            child: Text(
                '×${item.purchaseConversion} ${item.inventoryUnit}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textSecondary)),
          ),
          SizedBox(
            width: 100,
            child: Text(
                '+${item.inventoryAdded} ${item.inventoryUnit}',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.success)),
          ),
          SizedBox(
            width: 120,
            child: Text(item.formattedPrice,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13)),
          ),
          SizedBox(
            width: 120,
            child: Text(item.formattedSubtotal,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.primary)),
          ),
          // Price history button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: Icon(Icons.history_rounded,
                  size: 14,
                  color: DashboardTheme.textTertiary),
              tooltip: 'Riwayat Harga',
              padding: EdgeInsets.zero,
              onPressed: () => _showPriceHistory(
                  context, item.productId, item.productName),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceHistory(
      BuildContext context, String productId, String name) {
    showDialog(
      context: context,
      builder: (_) => _PriceHistoryDialog(
          productId: productId, productName: name),
    );
  }
}

// ---------------------------------------------------------------------------
// Price History Dialog
// ---------------------------------------------------------------------------

class _PriceHistoryDialog extends ConsumerWidget {
  const _PriceHistoryDialog(
      {required this.productId, required this.productName});
  final String productId;
  final String productName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync =
        ref.watch(purchaseHistoryProvider(productId));

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Riwayat Harga Beli',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(productName,
                  style: TextStyle(
                      fontSize: 13,
                      color: DashboardTheme.textSecondary)),
              const SizedBox(height: 16),
              historyAsync.when(
                loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                        child: CircularProgressIndicator())),
                error: (e, _) =>
                    ErrorView(message: e.toString()),
                data: (points) {
                  if (points.isEmpty) {
                    return const EmptyState(
                      title: 'Belum ada riwayat',
                      description: 'Belum ada data harga.',
                      icon: Icons.history_rounded,
                    );
                  }
                  return Column(
                    children: [
                      // Chart
                      SizedBox(
                        height: 160,
                        child: _PriceChart(points: points),
                      ),
                      const SizedBox(height: 16),
                      // Table
                      Row(children: const [
                        Expanded(
                            child: _ColumnHeader('Tanggal')),
                        SizedBox(
                            width: 100,
                            child: _ColumnHeader('Harga Beli',
                                textAlign: TextAlign.right)),
                        SizedBox(
                            width: 80,
                            child: _ColumnHeader('Qty',
                                textAlign: TextAlign.right)),
                        SizedBox(
                            width: 90,
                            child: _ColumnHeader('Perubahan',
                                textAlign: TextAlign.right)),
                      ]),
                      Divider(
                          height: 1,
                          color: DashboardTheme.border),
                      ...points.take(10).map((p) => Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 6),
                            child: Row(children: [
                              Expanded(
                                  child: Text(p.formattedDate,
                                      style: const TextStyle(
                                          fontSize: 12))),
                              SizedBox(
                                width: 100,
                                child: Text(p.formattedPrice,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w500)),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text('${p.quantity}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12)),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  p.formattedChange,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: p.changePercent > 0
                                        ? DashboardTheme.danger
                                        : p.changePercent < 0
                                            ? DashboardTheme
                                                .success
                                            : DashboardTheme
                                                .textTertiary,
                                  ),
                                ),
                              ),
                            ]),
                          )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.points});
  final List<PurchaseHistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final reversed = points.reversed.toList();
    final maxY = reversed
        .map((p) => p.purchasePrice.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    final spots = reversed.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), e.value.purchasePrice.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < reversed.length) {
                  return Text(reversed[idx].formattedDate
                      .substring(0, 6),
                      style: TextStyle(
                          fontSize: 9,
                          color: DashboardTheme.textTertiary));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (reversed.length - 1).toDouble().clamp(1, double.infinity),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: DashboardTheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: DashboardTheme.primary.withAlpha(15),
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
      child: Row(children: [
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
      ]),
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

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          if (!isLast)
            Container(
                width: 2, height: 32, color: DashboardTheme.borderLight),
        ]),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: DashboardTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
