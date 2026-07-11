import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
String _fmt(int n) => _idr.format(n);

enum TrendDirection { up, down, stable }
enum InsightPriority { high, medium, low }

// ---------------------------------------------------------------------------
// Business Health
// ---------------------------------------------------------------------------

class BusinessHealth {
  const BusinessHealth({
    required this.revenueToday,
    required this.revenueThisMonth,
    required this.purchasesThisMonth,
    required this.outstandingKasbon,
    required this.inventoryValue,
    required this.grossMarginEstimate,
    required this.revenueTrend,
    required this.kasbonTrend,
  });

  final int revenueToday;
  final int revenueThisMonth;
  final int purchasesThisMonth;
  final int outstandingKasbon;
  final int inventoryValue;
  final double grossMarginEstimate;
  final TrendDirection revenueTrend;
  final TrendDirection kasbonTrend;

  String get fmtToday => _fmt(revenueToday);
  String get fmtMonth => _fmt(revenueThisMonth);
  String get fmtPurchases => _fmt(purchasesThisMonth);
  String get fmtKasbon => _fmt(outstandingKasbon);
  String get fmtInventory => _fmt(inventoryValue);
  String get fmtMargin => '${grossMarginEstimate.toStringAsFixed(1)}%';
}

// ---------------------------------------------------------------------------
// Sales Analytics
// ---------------------------------------------------------------------------

class DailyRevenue {
  const DailyRevenue({required this.date, required this.revenue, required this.txCount});
  final DateTime date;
  final int revenue;
  final int txCount;
  String get label => DateFormat('d/M').format(date);
}

class SalesAnalytics {
  const SalesAnalytics({
    required this.dailyRevenue,
    required this.avgTransactionValue,
    required this.avgTransactionsPerDay,
    required this.topCategories,
    required this.peakHour,
    required this.weeklyRevenue,
  });

  final List<DailyRevenue> dailyRevenue;
  final int avgTransactionValue;
  final double avgTransactionsPerDay;
  final Map<String, int> topCategories;
  final int peakHour;
  final List<int> weeklyRevenue;

  String get fmtAvgTx => _fmt(avgTransactionValue);
}

// ---------------------------------------------------------------------------
// Inventory Analytics
// ---------------------------------------------------------------------------

class InventoryProduct {
  const InventoryProduct({required this.id, required this.name, required this.stock, required this.unit});
  final String id;
  final String name;
  final int stock;
  final String unit;
}

class InventoryAnalytics {
  const InventoryAnalytics({
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.deadStockProducts,
    required this.fastMovingProducts,
    required this.neverSoldProducts,
    required this.totalInventoryValue,
    required this.categoryDistribution,
  });

  final List<InventoryProduct> lowStockProducts;
  final List<InventoryProduct> outOfStockProducts;
  final List<InventoryProduct> deadStockProducts;
  final List<InventoryProduct> fastMovingProducts;
  final List<InventoryProduct> neverSoldProducts;
  final int totalInventoryValue;
  final Map<String, int> categoryDistribution; // category -> value

  String get fmtInventoryValue => _fmt(totalInventoryValue);
}

// ---------------------------------------------------------------------------
// Purchasing Analytics
// ---------------------------------------------------------------------------

class PurchaseTrend {
  const PurchaseTrend({required this.date, required this.amount});
  final DateTime date;
  final int amount;
  String get label => DateFormat('d/M').format(date);
}

class PurchasingAnalytics {
  const PurchasingAnalytics({
    required this.totalPurchaseValue,
    required this.purchaseFrequency,
    required this.avgPurchasePrice,
    required this.highestCostIncrease,
    required this.highestCostDecrease,
    required this.purchaseTrend,
  });

  final int totalPurchaseValue;
  final int purchaseFrequency;
  final int avgPurchasePrice;
  final String highestCostIncrease;
  final String highestCostDecrease;
  final List<PurchaseTrend> purchaseTrend;

  String get fmtTotal => _fmt(totalPurchaseValue);
  String get fmtAvg => _fmt(avgPurchasePrice);
}

// ---------------------------------------------------------------------------
// Pricing Analytics
// ---------------------------------------------------------------------------

class ProductMargin {
  const ProductMargin({
    required this.productId,
    required this.productName,
    required this.sellPrice,
    required this.buyPrice,
    required this.margin,
  });

  final String productId;
  final String productName;
  final int sellPrice;
  final int buyPrice;
  final double margin;

  bool get isNegative => margin < 0;
  bool get isMissingSell => sellPrice == 0;
  bool get isMissingBuy => buyPrice == 0;

  String get fmtMargin => '${margin.toStringAsFixed(1)}%';
  String get fmtSell => _fmt(sellPrice);
  String get fmtBuy => _fmt(buyPrice);
}

class PricingAnalytics {
  const PricingAnalytics({
    required this.highestMargin,
    required this.lowestMargin,
    required this.negativeMarginProducts,
    required this.missingSellPrice,
    required this.missingBuyPrice,
    required this.allMargins,
  });

  final ProductMargin? highestMargin;
  final ProductMargin? lowestMargin;
  final List<ProductMargin> negativeMarginProducts;
  final List<ProductMargin> missingSellPrice;
  final List<ProductMargin> missingBuyPrice;
  final List<ProductMargin> allMargins;
}

// ---------------------------------------------------------------------------
// Kasbon Analytics
// ---------------------------------------------------------------------------

class KasbonTrendPoint {
  const KasbonTrendPoint({required this.date, required this.outstanding});
  final DateTime date;
  final int outstanding;
  String get label => DateFormat('d/M').format(date);
}

class KasbonAnalytics {
  const KasbonAnalytics({
    required this.totalOutstanding,
    required this.recoveredThisMonth,
    required this.averageDebt,
    required this.largestCustomerName,
    required this.largestCustomerBalance,
    required this.customersOver30Days,
    required this.customersOver90Days,
    required this.agingBuckets,
  });

  final int totalOutstanding;
  final int recoveredThisMonth;
  final int averageDebt;
  final String largestCustomerName;
  final int largestCustomerBalance;
  final int customersOver30Days;
  final int customersOver90Days;
  final Map<String, int> agingBuckets;

  String get fmtOutstanding => _fmt(totalOutstanding);
  String get fmtRecovered => _fmt(recoveredThisMonth);
  String get fmtAverage => _fmt(averageDebt);
  String get fmtLargest => _fmt(largestCustomerBalance);
}

// ---------------------------------------------------------------------------
// Business Insights
// ---------------------------------------------------------------------------

class BusinessInsight {
  const BusinessInsight({
    required this.id,
    required this.priority,
    required this.title,
    required this.description,
    this.actionRoute,
    this.actionLabel,
  });

  final String id;
  final InsightPriority priority;
  final String title;
  final String description;
  final String? actionRoute;
  final String? actionLabel;
}
