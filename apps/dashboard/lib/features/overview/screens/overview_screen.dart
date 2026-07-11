import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/overview_models.dart';
import '../providers/overview_providers.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../theme/dashboard_theme.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DashboardTheme.sp32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          const PageHeader(
            title: 'Overview',
            subtitle: 'Ringkasan operasional warung hari ini.',
          ),
          const SizedBox(height: 24),

          // Section 1: KPI Cards
          _KpiSection(ref: ref),
          const SizedBox(height: 24),

          // Section 2 + 3: Activity + Alerts (side by side)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ActivitySection(ref: ref),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _AlertsSection(ref: ref),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _ActivitySection(ref: ref),
                  const SizedBox(height: 16),
                  _AlertsSection(ref: ref),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 4 + 5: Top products + Trend (side by side)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _TopProductsSection(ref: ref),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _TrendSection(ref: ref),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _TopProductsSection(ref: ref),
                  const SizedBox(height: 16),
                  _TrendSection(ref: ref),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: KPI Cards
// ---------------------------------------------------------------------------

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return metricsAsync.when(
      loading: () => LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 900 ? 6 : 3;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              6,
              (_) => SizedBox(
                width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                child: const MetricCardSkeleton(),
              ),
            ),
          );
        },
      ),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (metrics) => LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 1100
              ? 6
              : constraints.maxWidth > 700
                  ? 3
                  : 2;
          final cards = [
            (
              'Penjualan Hari Ini',
              formatIdr(metrics.todaySales),
              Icons.receipt_long_rounded,
              DashboardTheme.primary,
              null,
              null
            ),
            (
              'Transaksi',
              '${metrics.todayTransactions}',
              Icons.shopping_cart_rounded,
              DashboardTheme.success,
              null,
              null
            ),
            (
              'Rata-rata Transaksi',
              formatIdr(metrics.avgTransactionValue),
              Icons.trending_up_rounded,
              DashboardTheme.primary,
              null,
              null
            ),
            (
              'Kasbon Beredar',
              formatIdr(metrics.outstandingKasbon),
              Icons.account_balance_wallet_rounded,
              metrics.outstandingKasbon > 500000
                  ? DashboardTheme.danger
                  : DashboardTheme.warning,
              null,
              null
            ),
            (
              'Stok Rendah',
              '${metrics.lowStockCount} produk',
              Icons.warning_amber_rounded,
              metrics.lowStockCount > 0
                  ? DashboardTheme.warning
                  : DashboardTheme.success,
              null,
              null
            ),
            (
              'Total Produk',
              '${metrics.totalProducts}',
              Icons.inventory_2_rounded,
              DashboardTheme.textSecondary,
              null,
              null
            ),
          ];

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((c) {
              return SizedBox(
                width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                child: MetricCard(
                  label: c.$1,
                  value: c.$2,
                  icon: c.$3,
                  iconColor: c.$4,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Today's Activity
// ---------------------------------------------------------------------------

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(recentActivityProvider);

    return SectionCard(
      title: 'Aktivitas Terbaru',
      subtitle: '15 aktivitas terakhir',
      child: activityAsync.when(
        loading: () => Column(
          children: List.generate(
              5, (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SkeletonBox(
                        width: double.infinity, height: 48),
                  )),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (activities) {
          if (activities.isEmpty) {
            return const EmptyState(
              title: 'Belum ada aktivitas',
              description:
                  'Aktivitas penjualan, belanja, dan kasbon akan muncul di sini.',
              icon: Icons.history_rounded,
            );
          }
          return Column(
            children: activities.map((a) {
              return _ActivityRow(
                activity: a,
                onTap: a.relatedId != null
                    ? () {
                        final route = a.type == ActivityType.sale
                            ? '/sales/${a.relatedId}'
                            : a.type == ActivityType.restock
                                ? '/restocks/${a.relatedId}'
                                : '/customers/${a.relatedId}';
                        context.go(route);
                      }
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, this.onTap});
  final RecentActivity activity;
  final VoidCallback? onTap;

  IconData get _icon => switch (activity.type) {
        ActivityType.sale => Icons.receipt_long_rounded,
        ActivityType.restock => Icons.shopping_bag_rounded,
        ActivityType.kasbon => Icons.account_balance_wallet_rounded,
      };

  Color get _color => switch (activity.type) {
        ActivityType.sale => DashboardTheme.success,
        ActivityType.restock => DashboardTheme.primary,
        ActivityType.kasbon => DashboardTheme.warning,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_icon, size: 14, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(
                    '${activity.formattedDate} ${activity.formattedTime}',
                    style: TextStyle(
                        fontSize: 11,
                        color: DashboardTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              activity.formattedAmount,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activity.type == ActivityType.kasbon
                    ? DashboardTheme.warning
                    : DashboardTheme.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 14, color: DashboardTheme.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3: Alerts
// ---------------------------------------------------------------------------

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(dashboardAlertsProvider);

    return SectionCard(
      title: 'Peringatan',
      subtitle: 'Tindakan yang perlu diperhatikan',
      child: alertsAsync.when(
        loading: () => Column(
          children: List.generate(
              3,
              (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SkeletonBox(
                        width: double.infinity, height: 60),
                  )),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyState(
              title: 'Semua aman',
              description:
                  'Tidak ada peringatan saat ini.',
              icon: Icons.check_circle_rounded,
            );
          }
          return Column(
            children: alerts.map((a) => _AlertCard(alert: a)).toList(),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final DashboardAlert alert;

  Color get _color => switch (alert.severity) {
        AlertSeverity.danger => DashboardTheme.danger,
        AlertSeverity.warning => DashboardTheme.warning,
        AlertSeverity.info => DashboardTheme.primary,
      };

  IconData get _icon => switch (alert.severity) {
        AlertSeverity.danger => Icons.error_rounded,
        AlertSeverity.warning => Icons.warning_rounded,
        AlertSeverity.info => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withAlpha(12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _color,
                    )),
                const SizedBox(height: 2),
                Text(alert.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary)),
                if (alert.actionLabel != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () =>
                        context.go(alert.actionRoute ?? '/'),
                    child: Text(
                      alert.actionLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _color,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4: Top Selling Products
// ---------------------------------------------------------------------------

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final topAsync = ref.watch(topSellingProductsProvider);

    return SectionCard(
      title: 'Produk Terlaris',
      subtitle: 'Hari ini',
      child: topAsync.when(
        loading: () => Column(
          children: List.generate(5, (_) => const TableRowSkeleton()),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              title: 'Belum ada penjualan',
              description: 'Data produk terlaris akan muncul setelah ada transaksi.',
              icon: Icons.bar_chart_rounded,
            );
          }
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('#',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Produk',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.textSecondary)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text('Qty',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: Text('Pendapatan',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: DashboardTheme.borderLight),
              ...products.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${p.rank}',
                            style: TextStyle(
                                fontSize: 12,
                                color: DashboardTheme.textTertiary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.productName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${p.quantitySold}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: Text(
                          p.formattedRevenue,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: DashboardTheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 5: Daily Sales Trend
// ---------------------------------------------------------------------------

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final trendAsync = ref.watch(salesTrendProvider);

    return SectionCard(
      title: 'Tren Penjualan',
      subtitle: '30 hari terakhir',
      child: trendAsync.when(
        loading: () => const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (points) {
          if (points.every((p) => p.totalSales == 0)) {
            return const SizedBox(
              height: 220,
              child: EmptyState(
                title: 'Belum ada data',
                description: 'Tren penjualan akan muncul setelah ada transaksi.',
                icon: Icons.show_chart_rounded,
              ),
            );
          }
          return SizedBox(
            height: 220,
            child: _SalesLineChart(points: points),
          );
        },
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart({required this.points});
  final List<SalesTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points
        .map((p) => p.totalSales.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalSales.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: DashboardTheme.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: maxY > 0 ? maxY / 4 : 1,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _formatCompact(value.toInt()),
                  style: TextStyle(
                      fontSize: 10,
                      color: DashboardTheme.textTertiary),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < points.length) {
                  if (idx % 5 == 0 || idx == points.length - 1) {
                    return Text(
                      points[idx].label,
                      style: TextStyle(
                          fontSize: 10,
                          color: DashboardTheme.textTertiary),
                    );
                  }
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
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: DashboardTheme.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: DashboardTheme.primary.withAlpha(25),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final point =
                  idx < points.length ? points[idx] : null;
              return LineTooltipItem(
                point != null
                    ? '${point.label}\n${formatIdr(point.totalSales)}'
                    : '',
                TextStyle(
                  fontSize: 11,
                  color: DashboardTheme.surface,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return '$value';
  }
}
