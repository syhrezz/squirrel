import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/overview_models.dart';

/// Repository that reads business data directly from Supabase.
/// No SQLite, no offline mode — dashboard always works online.
abstract class OverviewRepository {
  Future<DashboardMetrics> getDashboardMetrics();
  Future<List<RecentActivity>> getRecentActivity({int limit = 15});
  Future<List<DashboardAlert>> getAlerts();
  Future<List<TopSellingProduct>> getTopSellingProducts({int limit = 10});
  Future<List<SalesTrendPoint>> getSalesTrend({int days = 30});
}

class SupabaseOverviewRepository implements OverviewRepository {
  SupabaseOverviewRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  // ---------------------------------------------------------------------------
  // KPI Metrics
  // ---------------------------------------------------------------------------

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    // Today's sales
    final salesRows = await _client
        .from('sales')
        .select('total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', todayStart);

    final todaySales = (salesRows as List)
        .fold<int>(0, (sum, r) => sum + (r['total_amount'] as int? ?? 0));
    final todayTransactions = salesRows.length;
    final avgTransaction = todayTransactions > 0
        ? todaySales ~/ todayTransactions
        : 0;

    // Outstanding kasbon
    final debtRows = await _client
        .from('debt_transactions')
        .select('type, amount')
        .eq('organization_id', _orgId);

    int kasbon = 0;
    for (final r in debtRows as List) {
      final amt = r['amount'] as int? ?? 0;
      kasbon += r['type'] == 'debt' ? amt : -amt;
    }

    // Low stock + total products
    final productRows = await _client
        .from('products')
        .select('current_stock, is_active')
        .eq('organization_id', _orgId)
        .eq('is_active', true);

    final totalProducts = (productRows as List).length;
    final lowStock =
        productRows.where((r) => (r['current_stock'] as int? ?? 0) <= 3).length;

    return DashboardMetrics(
      todaySales: todaySales,
      todayTransactions: todayTransactions,
      avgTransactionValue: avgTransaction,
      outstandingKasbon: kasbon > 0 ? kasbon : 0,
      lowStockCount: lowStock,
      totalProducts: totalProducts,
    );
  }

  // ---------------------------------------------------------------------------
  // Recent Activity
  // ---------------------------------------------------------------------------

  @override
  Future<List<RecentActivity>> getRecentActivity(
      {int limit = 15}) async {
    final activities = <RecentActivity>[];

    // Sales
    final salesRows = await _client
        .from('sales')
        .select('id, total_amount, created_at, created_by')
        .eq('organization_id', _orgId)
        .order('created_at', ascending: false)
        .limit(limit);

    for (final r in salesRows as List) {
      activities.add(RecentActivity(
        id: r['id'] as String,
        type: ActivityType.sale,
        title: 'Penjualan',
        subtitle: r['created_by'] as String? ?? '',
        amount: r['total_amount'] as int? ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int),
        relatedId: r['id'] as String,
      ));
    }

    // Restocks
    final restockRows = await _client
        .from('restocks')
        .select('id, total_amount, created_at, created_by')
        .eq('organization_id', _orgId)
        .order('created_at', ascending: false)
        .limit(limit);

    for (final r in restockRows as List) {
      activities.add(RecentActivity(
        id: r['id'] as String,
        type: ActivityType.restock,
        title: 'Belanja Barang',
        subtitle: r['created_by'] as String? ?? '',
        amount: r['total_amount'] as int? ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int),
        relatedId: r['id'] as String,
      ));
    }

    // Debt transactions
    final debtRows = await _client
        .from('debt_transactions')
        .select('id, type, amount, created_at, customer_id')
        .eq('organization_id', _orgId)
        .order('created_at', ascending: false)
        .limit(limit);

    for (final r in debtRows as List) {
      final isDebt = r['type'] == 'debt';
      activities.add(RecentActivity(
        id: r['id'] as String,
        type: ActivityType.kasbon,
        title: isDebt ? 'Kasbon Baru' : 'Pembayaran Kasbon',
        subtitle: r['customer_id'] as String? ?? '',
        amount: r['amount'] as int? ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int),
        relatedId: r['customer_id'] as String?,
      ));
    }

    // Sort by timestamp descending, take first `limit`
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------

  @override
  Future<List<DashboardAlert>> getAlerts() async {
    final alerts = <DashboardAlert>[];

    // Low/zero stock products
    final productRows = await _client
        .from('products')
        .select('id, name, current_stock')
        .eq('organization_id', _orgId)
        .eq('is_active', true)
        .lte('current_stock', 3)
        .order('current_stock', ascending: true)
        .limit(10);

    for (final r in productRows as List) {
      final stock = r['current_stock'] as int? ?? 0;
      alerts.add(DashboardAlert(
        id: 'stock_${r['id']}',
        severity: stock == 0 ? AlertSeverity.danger : AlertSeverity.warning,
        title: stock == 0
            ? '${r['name']} — Stok Habis'
            : '${r['name']} — Stok Rendah',
        description: stock == 0
            ? 'Produk ini sudah habis. Segera restock.'
            : 'Stok tersisa $stock unit.',
        actionLabel: 'Lihat Produk',
        actionRoute: '/products/${r['id']}',
      ));
    }

    // High kasbon customers — top 3
    final debtRows = await _client
        .from('debt_transactions')
        .select('customer_id, type, amount')
        .eq('organization_id', _orgId);

    final balances = <String, int>{};
    for (final r in debtRows as List) {
      final cid = r['customer_id'] as String;
      final amt = r['amount'] as int? ?? 0;
      balances[cid] = (balances[cid] ?? 0) +
          (r['type'] == 'debt' ? amt : -amt);
    }

    final sorted = balances.entries
        .where((e) => e.value > 100000)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted.take(3)) {
      alerts.add(DashboardAlert(
        id: 'kasbon_${entry.key}',
        severity: AlertSeverity.info,
        title: 'Kasbon Tinggi',
        description:
            'Pelanggan memiliki hutang ${formatIdr(entry.value)}.',
        actionLabel: 'Lihat Pelanggan',
        actionRoute: '/customers/${entry.key}',
      ));
    }

    return alerts;
  }

  // ---------------------------------------------------------------------------
  // Top Selling Products
  // ---------------------------------------------------------------------------

  @override
  Future<List<TopSellingProduct>> getTopSellingProducts(
      {int limit = 10}) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;

    // Get sale_items joined with sales for today
    final rows = await _client
        .from('sale_items')
        .select('product_id, quantity, subtotal, sales!inner(created_at, organization_id)')
        .eq('sales.organization_id', _orgId)
        .gte('sales.created_at', todayStart);

    // Aggregate by product
    final productMap = <String, Map<String, int>>{};
    for (final r in rows as List) {
      final pid = r['product_id'] as String;
      final qty = r['quantity'] as int? ?? 0;
      final sub = r['subtotal'] as int? ?? 0;
      productMap[pid] ??= {'qty': 0, 'revenue': 0};
      productMap[pid]!['qty'] = productMap[pid]!['qty']! + qty;
      productMap[pid]!['revenue'] = productMap[pid]!['revenue']! + sub;
    }

    if (productMap.isEmpty) return [];

    // Fetch product names
    final productIds = productMap.keys.toList();
    final productRows = await _client
        .from('products')
        .select('id, name')
        .inFilter('id', productIds);

    final nameMap = <String, String>{};
    for (final r in productRows as List) {
      nameMap[r['id'] as String] = r['name'] as String;
    }

    // Build sorted list
    final result = productMap.entries.map((e) {
      return TopSellingProduct(
        productId: e.key,
        productName: nameMap[e.key] ?? e.key.substring(0, 8),
        quantitySold: e.value['qty']!,
        revenue: e.value['revenue']!,
        rank: 0,
      );
    }).toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return result
        .take(limit)
        .toList()
        .asMap()
        .entries
        .map((e) => TopSellingProduct(
              productId: e.value.productId,
              productName: e.value.productName,
              quantitySold: e.value.quantitySold,
              revenue: e.value.revenue,
              rank: e.key + 1,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Sales Trend
  // ---------------------------------------------------------------------------

  @override
  Future<List<SalesTrendPoint>> getSalesTrend({int days = 30}) async {
    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day - days)
            .millisecondsSinceEpoch;

    final rows = await _client
        .from('sales')
        .select('created_at, total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', startDate)
        .order('created_at', ascending: true);

    // Group by day
    final dayMap = <String, Map<String, int>>{};
    for (final r in rows as List) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          r['created_at'] as int);
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      dayMap[key] ??= {'total': 0, 'count': 0};
      dayMap[key]!['total'] =
          dayMap[key]!['total']! + (r['total_amount'] as int? ?? 0);
      dayMap[key]!['count'] = dayMap[key]!['count']! + 1;
    }

    // Fill missing days with zeros
    final result = <SalesTrendPoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final data = dayMap[key];
      result.add(SalesTrendPoint(
        date: day,
        totalSales: data?['total'] ?? 0,
        transactionCount: data?['count'] ?? 0,
      ));
    }

    return result;
  }
}
