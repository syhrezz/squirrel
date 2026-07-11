import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../theme/dashboard_theme.dart';
import '../models/analytics_models.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Analytics',
                  subtitle: 'Ringkasan kesehatan bisnis.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(businessHealthProvider);
                  ref.invalidate(salesAnalyticsProvider);
                  ref.invalidate(inventoryAnalyticsProvider);
                  ref.invalidate(purchasingAnalyticsProvider);
                  ref.invalidate(pricingAnalyticsProvider);
                  ref.invalidate(kasbonAnalyticsProvider);
                  ref.invalidate(businessInsightsProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InsightsSection(),
          const SizedBox(height: 24),
          _HealthSection(),
          const SizedBox(height: 24),
          _SalesSection(),
          const SizedBox(height: 24),
          _InventorySection(),
          const SizedBox(height: 24),
          _PurchasingSection(),
          const SizedBox(height: 24),
          _PricingSection(),
          const SizedBox(height: 24),
          _KasbonSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights
// ---------------------------------------------------------------------------

class _InsightsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessInsightsProvider);
    return SectionCard(
      title: 'Business Insights',
      subtitle: 'Temuan otomatis berdasarkan data',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (insights) {
          if (insights.isEmpty) {
            return const EmptyState(
              title: 'Semua terlihat baik',
              icon: Icons.check_circle_rounded,
              description: 'Tidak ada temuan yang memerlukan perhatian.',
            );
          }
          return Column(
              children: insights.map((i) => _InsightCard(i)).toList());
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard(this.insight);
  final BusinessInsight insight;

  Color get _c => switch (insight.priority) {
        InsightPriority.high => DashboardTheme.danger,
        InsightPriority.medium => DashboardTheme.warning,
        InsightPriority.low => DashboardTheme.primary,
      };

  IconData get _i => switch (insight.priority) {
        InsightPriority.high => Icons.error_rounded,
        InsightPriority.medium => Icons.warning_rounded,
        InsightPriority.low => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _c.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _c.withAlpha(40)),
      ),
      child: Row(children: [
        Icon(_i, size: 16, color: _c),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(insight.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _c)),
            const SizedBox(height: 2),
            Text(insight.description,
                style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _c.withAlpha(20), borderRadius: BorderRadius.circular(12)),
          child: Text(
            switch (insight.priority) {
              InsightPriority.high => 'Tinggi',
              InsightPriority.medium => 'Sedang',
              InsightPriority.low => 'Rendah',
            },
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _c),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Business Health
// ---------------------------------------------------------------------------

class _HealthSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(businessHealthProvider);
    return SectionCard(
      title: 'Kesehatan Bisnis',
      subtitle: 'Metrik utama hari ini',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (h) => LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 900 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: w, child: MetricCard(label: 'Revenue Hari Ini', value: h.fmtToday, icon: Icons.today_rounded, iconColor: DashboardTheme.primary, change: h.revenueTrend == TrendDirection.up ? 'Naik' : h.revenueTrend == TrendDirection.down ? 'Turun' : 'Stabil', changePositive: h.revenueTrend == TrendDirection.up)),
            SizedBox(width: w, child: MetricCard(label: 'Revenue Bulan Ini', value: h.fmtMonth, icon: Icons.calendar_month_rounded, iconColor: DashboardTheme.success)),
            SizedBox(width: w, child: MetricCard(label: 'Pembelian Bulan Ini', value: h.fmtPurchases, icon: Icons.shopping_bag_rounded, iconColor: DashboardTheme.warning)),
            SizedBox(width: w, child: MetricCard(label: 'Outstanding Kasbon', value: h.fmtKasbon, icon: Icons.account_balance_wallet_rounded, iconColor: h.outstandingKasbon > 1000000 ? DashboardTheme.danger : DashboardTheme.warning, change: h.kasbonTrend == TrendDirection.up ? 'Naik' : 'Turun', changePositive: h.kasbonTrend == TrendDirection.down)),
            SizedBox(width: w, child: MetricCard(label: 'Nilai Inventori', value: h.fmtInventory, icon: Icons.inventory_2_rounded, iconColor: DashboardTheme.primary)),
            SizedBox(width: w, child: MetricCard(label: 'Estimasi Margin', value: h.fmtMargin, icon: Icons.trending_up_rounded, iconColor: h.grossMarginEstimate < 10 ? DashboardTheme.danger : DashboardTheme.success)),
          ]);
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Sales Performance
// ---------------------------------------------------------------------------

class _SalesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salesAnalyticsProvider);
    return SectionCard(
      title: 'Performa Penjualan',
      subtitle: '30 hari terakhir',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (s) => Column(children: [
          Row(children: [
            Expanded(child: _Stat('Rata-rata Transaksi', s.fmtAvgTx)),
            Expanded(child: _Stat('Transaksi/Hari', s.avgTransactionsPerDay.toStringAsFixed(1))),
            Expanded(child: _Stat('Jam Puncak', '${s.peakHour}:00')),
          ]),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('Revenue Harian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          SizedBox(height: 180, child: _RevenueChart(data: s.dailyRevenue)),
          if (s.topCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Kategori Terlaris', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            ..._buildCategoryBars(s.topCategories),
          ],
        ]),
      ),
    );
  }

  List<Widget> _buildCategoryBars(Map<String, int> cats) {
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);
    return sorted.take(5).map((e) {
      final pct = total > 0 ? e.value / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          SizedBox(width: 120, child: Text(e.key, style: const TextStyle(fontSize: 12))),
          Expanded(child: LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFF3F4F6), valueColor: AlwaysStoppedAnimation(DashboardTheme.primary))),
          const SizedBox(width: 8),
          Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
        ]),
      );
    }).toList();
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<DailyRevenue> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((d) => d.revenue.toDouble()).fold<double>(0, (a, b) => a > b ? a : b);
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble())).toList();

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: DashboardTheme.borderLight, strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48, getTitlesWidget: (v, _) => Text(_cmp(v.toInt()), style: TextStyle(fontSize: 9, color: DashboardTheme.textTertiary)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, interval: 5, getTitlesWidget: (v, _) { final i = v.toInt(); if (i >= 0 && i < data.length && i % 5 == 0) return Text(data[i].label, style: TextStyle(fontSize: 9, color: DashboardTheme.textTertiary)); return const SizedBox.shrink(); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0, maxX: (data.length - 1).toDouble(), minY: 0, maxY: maxY * 1.2,
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: DashboardTheme.primary, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: DashboardTheme.primary.withAlpha(20)))],
    ));
  }

  String _cmp(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return '$v';
  }
}

// ---------------------------------------------------------------------------
// Section 3: Inventory
// ---------------------------------------------------------------------------

class _InventorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryAnalyticsProvider);
    return SectionCard(
      title: 'Kesehatan Inventori',
      subtitle: 'Status stok saat ini',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (inv) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _Stat('Habis Stok', '${inv.outOfStockProducts.length}', color: DashboardTheme.danger)),
            Expanded(child: _Stat('Stok Rendah', '${inv.lowStockProducts.length}', color: DashboardTheme.warning)),
            Expanded(child: _Stat('Dead Stock', '${inv.deadStockProducts.length}', color: DashboardTheme.textSecondary)),
            Expanded(child: _Stat('Fast Moving', '${inv.fastMovingProducts.length}', color: DashboardTheme.success)),
            Expanded(child: _Stat('Belum Terjual', '${inv.neverSoldProducts.length}', color: DashboardTheme.textTertiary)),
          ]),
          if (inv.outOfStockProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Produk Habis Stok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: inv.outOfStockProducts.take(8).map((p) => _Tag(p.name, DashboardTheme.danger)).toList()),
          ],
          if (inv.fastMovingProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Produk Terlaris', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: inv.fastMovingProducts.take(8).map((p) => _Tag(p.name, DashboardTheme.success)).toList()),
          ],
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4: Purchasing
// ---------------------------------------------------------------------------

class _PurchasingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(purchasingAnalyticsProvider);
    return SectionCard(
      title: 'Pembelian',
      subtitle: '30 hari terakhir',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (p) => Column(children: [
          Row(children: [
            Expanded(child: _Stat('Total Pembelian', p.fmtTotal)),
            Expanded(child: _Stat('Frekuensi', '${p.purchaseFrequency}x')),
            Expanded(child: _Stat('Rata-rata Harga', p.fmtAvg)),
            Expanded(child: _Stat('Harga Naik', p.highestCostIncrease)),
            Expanded(child: _Stat('Harga Turun', p.highestCostDecrease)),
          ]),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('Tren Pembelian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          SizedBox(height: 150, child: _PurchaseChart(data: p.purchaseTrend)),
        ]),
      ),
    );
  }
}

class _PurchaseChart extends StatelessWidget {
  const _PurchaseChart({required this.data});
  final List<PurchaseTrend> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((d) => d.amount.toDouble()).fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18, interval: 5, getTitlesWidget: (v, _) { final i = v.toInt(); if (i >= 0 && i < data.length && i % 5 == 0) return Text(data[i].label, style: TextStyle(fontSize: 9, color: DashboardTheme.textTertiary)); return const SizedBox.shrink(); })),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.amount.toDouble(), color: DashboardTheme.primary.withAlpha(180), width: 6, borderRadius: BorderRadius.circular(2))])).toList(),
      maxY: maxY * 1.2,
    ));
  }
}

// ---------------------------------------------------------------------------
// Section 5: Pricing
// ---------------------------------------------------------------------------

class _PricingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pricingAnalyticsProvider);
    return SectionCard(
      title: 'Harga & Margin',
      subtitle: 'Estimasi margin berdasarkan harga jual dan beli',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _Stat('Margin Tertinggi', p.highestMargin != null ? '${p.highestMargin!.productName} (${p.highestMargin!.fmtMargin})' : '—', color: DashboardTheme.success)),
            Expanded(child: _Stat('Margin Terendah', p.lowestMargin != null ? '${p.lowestMargin!.productName} (${p.lowestMargin!.fmtMargin})' : '—', color: DashboardTheme.danger)),
            Expanded(child: _Stat('Margin Negatif', '${p.negativeMarginProducts.length} produk', color: p.negativeMarginProducts.isNotEmpty ? DashboardTheme.danger : DashboardTheme.success)),
            Expanded(child: _Stat('Tanpa Harga', '${p.missingSellPrice.length + p.missingBuyPrice.length} produk', color: DashboardTheme.warning)),
          ]),
          if (p.negativeMarginProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Produk Dijual Rugi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...p.negativeMarginProducts.take(5).map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(m.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                Text('Jual: ${m.fmtSell}', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
                const SizedBox(width: 12),
                Text('Beli: ${m.fmtBuy}', style: TextStyle(fontSize: 12, color: DashboardTheme.textSecondary)),
                const SizedBox(width: 12),
                Text(m.fmtMargin, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DashboardTheme.danger)),
              ]),
            )),
          ],
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 6: Kasbon
// ---------------------------------------------------------------------------

class _KasbonSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kasbonAnalyticsProvider);
    return SectionCard(
      title: 'Kesehatan Kasbon',
      subtitle: 'Status hutang pelanggan',
      child: async.when(
        loading: () => const _Loading(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (k) => Column(children: [
          Row(children: [
            Expanded(child: _Stat('Total Outstanding', k.fmtOutstanding, color: k.totalOutstanding > 1000000 ? DashboardTheme.danger : DashboardTheme.textPrimary)),
            Expanded(child: _Stat('Recovered Bulan Ini', k.fmtRecovered, color: DashboardTheme.success)),
            Expanded(child: _Stat('Rata-rata Hutang', k.fmtAverage)),
            Expanded(child: _Stat('Terbesar', k.largestCustomerName, color: DashboardTheme.danger)),
            Expanded(child: _Stat('>30 Hari', '${k.customersOver30Days}', color: DashboardTheme.warning)),
            Expanded(child: _Stat('>90 Hari', '${k.customersOver90Days}', color: DashboardTheme.danger)),
          ]),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('Umur Hutang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          _AgingBar(buckets: k.agingBuckets),
        ]),
      ),
    );
  }
}

class _AgingBar extends StatelessWidget {
  const _AgingBar({required this.buckets});
  final Map<String, int> buckets;

  @override
  Widget build(BuildContext context) {
    final total = buckets.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return const Text('Tidak ada hutang', style: TextStyle(fontSize: 12));

    final colors = [DashboardTheme.success, DashboardTheme.warning, DashboardTheme.danger, const Color(0xFF7C3AED)];
    final entries = buckets.entries.toList();

    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 16,
          child: Row(children: entries.asMap().entries.map((e) {
            final frac = e.value.value / total;
            return Flexible(flex: (frac * 100).clamp(1, 100).round(), child: Container(color: colors[e.key % colors.length]));
          }).toList()),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: entries.asMap().entries.map((e) => Expanded(child: Column(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 4),
        Text(e.value.key, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
      ]))).toList()),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: DashboardTheme.textSecondary), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? DashboardTheme.textPrimary), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(40))),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
