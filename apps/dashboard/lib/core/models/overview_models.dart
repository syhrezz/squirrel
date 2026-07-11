import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatIdr(int amount) => _idr.format(amount);

/// KPI metrics for the overview page — all computed for today.
class DashboardMetrics {
  const DashboardMetrics({
    required this.todaySales,
    required this.todayTransactions,
    required this.avgTransactionValue,
    required this.outstandingKasbon,
    required this.lowStockCount,
    required this.totalProducts,
  });

  final int todaySales;
  final int todayTransactions;
  final int avgTransactionValue;
  final int outstandingKasbon;
  final int lowStockCount;
  final int totalProducts;

  static const empty = DashboardMetrics(
    todaySales: 0,
    todayTransactions: 0,
    avgTransactionValue: 0,
    outstandingKasbon: 0,
    lowStockCount: 0,
    totalProducts: 0,
  );
}

/// One item in the activity timeline.
enum ActivityType { sale, restock, kasbon }

class RecentActivity {
  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.timestamp,
    this.relatedId,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime timestamp;
  final String? relatedId;

  String get formattedTime =>
      DateFormat('HH:mm').format(timestamp);
  String get formattedDate =>
      DateFormat('d MMM').format(timestamp);
  String get formattedAmount => formatIdr(amount);
}

/// A single alert card shown in the Alerts section.
enum AlertSeverity { warning, danger, info }

class DashboardAlert {
  const DashboardAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String? actionLabel;
  final String? actionRoute;
}

/// One row in the Top Selling Products table.
class TopSellingProduct {
  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
    required this.rank,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final int revenue;
  final int rank;

  String get formattedRevenue => formatIdr(revenue);
}

/// One data point in the 30-day sales trend chart.
class SalesTrendPoint {
  const SalesTrendPoint({
    required this.date,
    required this.totalSales,
    required this.transactionCount,
  });

  final DateTime date;
  final int totalSales;
  final int transactionCount;

  String get label => DateFormat('d/M').format(date);
}
