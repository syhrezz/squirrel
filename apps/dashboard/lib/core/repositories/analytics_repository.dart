import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/analytics/models/analytics_models.dart';

abstract class AnalyticsRepository {
  Future<BusinessHealth> getBusinessHealth();
  Future<SalesAnalytics> getSalesAnalytics();
  Future<InventoryAnalytics> getInventoryAnalytics();
  Future<PurchasingAnalytics> getPurchasingAnalytics();
  Future<PricingAnalytics> getPricingAnalytics();
  Future<KasbonAnalytics> getKasbonAnalytics();
  Future<List<BusinessInsight>> getBusinessInsights();
}

class SupabaseAnalyticsRepository implements AnalyticsRepository {
  SupabaseAnalyticsRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _dayStart(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
  int _monthStart(DateTime dt) =>
      DateTime(dt.year, dt.month, 1).millisecondsSinceEpoch;
  int _daysAgo(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days)
        .millisecondsSinceEpoch;
  }

  // ---------------------------------------------------------------------------
  // getBusinessHealth
  // ---------------------------------------------------------------------------

  @override
  Future<BusinessHealth> getBusinessHealth() async {
    final now = DateTime.now();
    final todayMs = _dayStart(now);
    final monthMs = _monthStart(now);
    final prevMonthMs = _monthStart(
        DateTime(now.year, now.month - 1, 1));

    // Revenue today
    final todaySales = await _client
        .from('sales')
        .select('total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', todayMs);
    final revenueToday = (todaySales as List)
        .fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    // Revenue this month
    final monthSales = await _client
        .from('sales')
        .select('total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', monthMs);
    final revenueMonth = (monthSales as List)
        .fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    // Revenue prev month for trend
    final prevSales = await _client
        .from('sales')
        .select('total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', prevMonthMs)
        .lt('created_at', monthMs);
    final revenuePrev = (prevSales as List)
        .fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    final revTrend = revenueMonth > revenuePrev * 1.02
        ? TrendDirection.up
        : revenueMonth < revenuePrev * 0.98
            ? TrendDirection.down
            : TrendDirection.stable;

    // Purchases this month
    final monthRestocks = await _client
        .from('restocks')
        .select('total_amount')
        .eq('organization_id', _orgId)
        .gte('created_at', monthMs);
    final purchasesMonth = (monthRestocks as List)
        .fold<int>(0, (s, r) => s + (r['total_amount'] as int? ?? 0));

    // Outstanding kasbon
    final allTx = await _client
        .from('debt_transactions')
        .select('type, amount')
        .eq('organization_id', _orgId);
    int kasbon = 0;
    for (final tx in allTx as List) {
      kasbon += tx['type'] == 'debt'
          ? (tx['amount'] as int? ?? 0)
          : -(tx['amount'] as int? ?? 0);
    }

    // Inventory value
    final products = await _client
        .from('products')
        .select('current_stock, last_buy_price')
        .eq('organization_id', _orgId)
        .eq('is_active', true);
    int invValue = 0;
    int totalSell = 0;
    int totalBuy = 0;
    int priceCount = 0;
    for (final p in products as List) {
      invValue += (p['current_stock'] as int? ?? 0) *
          (p['last_buy_price'] as int? ?? 0);
      final sell = p['sell_price'] as int? ?? 0;
      final buy = p['last_buy_price'] as int? ?? 0;
      if (sell > 0 && buy > 0) {
        totalSell += sell;
        totalBuy += buy;
        priceCount++;
      }
    }
    final margin = priceCount > 0
        ? (totalSell - totalBuy) / totalSell * 100
        : 0.0;

    // Kasbon trend (compare this month vs prev month payments)
    int kasbonMs = _monthStart(now);
    int kasbonPrev = _monthStart(DateTime(now.year, now.month - 1));
    int thisMonthNew = 0;
    int prevMonthNew = 0;
    for (final tx in allTx) {
      if (tx['type'] == 'debt') {
        final ts = tx['created_at'] as int? ?? 0;
        if (ts >= kasbonMs) thisMonthNew += tx['amount'] as int? ?? 0;
        if (ts >= kasbonPrev && ts < kasbonMs) {
          prevMonthNew += tx['amount'] as int? ?? 0;
        }
      }
    }
    final kasbonTrend = thisMonthNew > prevMonthNew * 1.05
        ? TrendDirection.up
        : thisMonthNew < prevMonthNew * 0.95
            ? TrendDirection.down
            : TrendDirection.stable;

    return BusinessHealth(
      revenueToday: revenueToday,
      revenueThisMonth: revenueMonth,
      purchasesThisMonth: purchasesMonth,
      outstandingKasbon: kasbon > 0 ? kasbon : 0,
      inventoryValue: invValue,
      grossMarginEstimate: margin.toDouble(),
      revenueTrend: revTrend,
      kasbonTrend: kasbonTrend,
    );
  }

  // ---------------------------------------------------------------------------
  // getSalesAnalytics
  // ---------------------------------------------------------------------------

  @override
  Future<SalesAnalytics> getSalesAnalytics() async {
    final since30 = _daysAgo(30);
    final salesRows = await _client
        .from('sales')
        .select('total_amount, created_at')
        .eq('organization_id', _orgId)
        .gte('created_at', since30)
        .order('created_at', ascending: true);

    final now = DateTime.now();
    final dayMap = <String, Map<String, int>>{};
    final hourMap = <int, int>{};

    for (final r in salesRows as List) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          r['created_at'] as int);
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      dayMap[key] ??= {'total': 0, 'count': 0};
      dayMap[key]!['total'] =
          dayMap[key]!['total']! + (r['total_amount'] as int? ?? 0);
      dayMap[key]!['count'] = dayMap[key]!['count']! + 1;
      hourMap[dt.hour] = (hourMap[dt.hour] ?? 0) + 1;
    }

    final daily = <DailyRevenue>[];
    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final k =
          '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      daily.add(DailyRevenue(
        date: d,
        revenue: dayMap[k]?['total'] ?? 0,
        txCount: dayMap[k]?['count'] ?? 0,
      ));
    }

    final totalRevenue = daily.fold<int>(0, (s, d) => s + d.revenue);
    final totalTx = daily.fold<int>(0, (s, d) => s + d.txCount);
    final avgTx = totalTx > 0 ? totalRevenue ~/ totalTx : 0;
    final peakHour = hourMap.isEmpty
        ? 0
        : (hourMap.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    // Weekly revenue (last 4 weeks)
    final weekRevenue = [0, 0, 0, 0];
    for (final d in daily) {
      final daysAgo =
          now.difference(d.date).inDays;
      final weekIdx = (daysAgo ~/ 7).clamp(0, 3);
      weekRevenue[weekIdx] += d.revenue;
    }

    // Top categories from sale_items + products
    final saleItemRows = await _client
        .from('sale_items')
        .select('product_id, subtotal, sales!inner(created_at, organization_id)')
        .eq('sales.organization_id', _orgId)
        .gte('sales.created_at', since30);

    final catRevenue = <String, int>{};
    final pids = (saleItemRows as List)
        .map((r) => r['product_id'] as String)
        .toSet()
        .toList();

    if (pids.isNotEmpty) {
      final pRows = await _client
          .from('products')
          .select('id, category')
          .inFilter('id', pids);
      final catMap = <String, String>{};
      for (final r in pRows as List) {
        catMap[r['id'] as String] = r['category'] as String? ?? 'lainnya';
      }
      for (final r in saleItemRows) {
        final cat = catMap[r['product_id'] as String] ?? 'lainnya';
        catRevenue[cat] =
            (catRevenue[cat] ?? 0) + (r['subtotal'] as int? ?? 0);
      }
    }

    return SalesAnalytics(
      dailyRevenue: daily,
      avgTransactionValue: avgTx,
      avgTransactionsPerDay: totalTx / 30.0,
      topCategories: catRevenue,
      peakHour: peakHour,
      weeklyRevenue: weekRevenue,
    );
  }

  // ---------------------------------------------------------------------------
  // getInventoryAnalytics
  // ---------------------------------------------------------------------------

  @override
  Future<InventoryAnalytics> getInventoryAnalytics() async {
    final productRows = await _client
        .from('products')
        .select('id, name, current_stock, inventory_unit, last_buy_price, sell_price, category')
        .eq('organization_id', _orgId)
        .eq('is_active', true);

    // Products sold in last 30 days
    final since30 = _daysAgo(30);
    final soldRows = await _client
        .from('sale_items')
        .select('product_id, quantity, sales!inner(created_at, organization_id)')
        .eq('sales.organization_id', _orgId)
        .gte('sales.created_at', since30);

    final soldMap = <String, int>{};
    for (final r in soldRows as List) {
      final pid = r['product_id'] as String;
      soldMap[pid] = (soldMap[pid] ?? 0) + (r['quantity'] as int? ?? 0);
    }

    final low = <InventoryProduct>[];
    final outOf = <InventoryProduct>[];
    final dead = <InventoryProduct>[];
    final fast = <InventoryProduct>[];
    final neverSold = <InventoryProduct>[];
    int invValue = 0;
    final catValue = <String, int>{};

    for (final r in productRows as List) {
      final id = r['id'] as String;
      final stock = r['current_stock'] as int? ?? 0;
      final buyPrice = r['last_buy_price'] as int? ?? 0;
      final cat = r['category'] as String? ?? 'lainnya';
      final p = InventoryProduct(
          id: id,
          name: r['name'] as String,
          stock: stock,
          unit: r['inventory_unit'] as String? ?? 'pcs');

      invValue += stock * buyPrice;
      catValue[cat] = (catValue[cat] ?? 0) + stock * buyPrice;

      if (stock <= 0) {
        outOf.add(p);
      } else if (stock <= 3) {
        low.add(p);
      }

      final sold = soldMap[id] ?? 0;
      if (sold == 0 && stock > 0) {
        neverSold.add(p);
        if (stock > 10) dead.add(p);
      } else if (sold > 10) {
        fast.add(p);
      }
    }

    fast.sort((a, b) => (soldMap[b.id] ?? 0).compareTo(soldMap[a.id] ?? 0));

    return InventoryAnalytics(
      lowStockProducts: low,
      outOfStockProducts: outOf,
      deadStockProducts: dead,
      fastMovingProducts: fast.take(10).toList(),
      neverSoldProducts: neverSold,
      totalInventoryValue: invValue,
      categoryDistribution: catValue,
    );
  }

  // ---------------------------------------------------------------------------
  // getPurchasingAnalytics
  // ---------------------------------------------------------------------------

  @override
  Future<PurchasingAnalytics> getPurchasingAnalytics() async {
    final since30 = _daysAgo(30);
    final restockRows = await _client
        .from('restocks')
        .select('total_amount, created_at')
        .eq('organization_id', _orgId)
        .gte('created_at', since30)
        .order('created_at', ascending: true);

    final now = DateTime.now();
    final trend = <PurchaseTrend>[];
    final dayMap = <String, int>{};
    int totalPurchase = 0;

    for (final r in restockRows as List) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          r['created_at'] as int);
      final k =
          '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      dayMap[k] = (dayMap[k] ?? 0) + (r['total_amount'] as int? ?? 0);
      totalPurchase += r['total_amount'] as int? ?? 0;
    }

    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final k =
          '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      trend.add(PurchaseTrend(
          date: d, amount: dayMap[k] ?? 0));
    }

    // Price changes
    final itemRows = await _client
        .from('restock_items')
        .select('product_id, purchase_price, restocks!inner(created_at, organization_id)')
        .eq('restocks.organization_id', _orgId)
        .gte('restocks.created_at', since30)
        .order('restocks(created_at)', ascending: true);

    final priceChanges = <String, List<int>>{};
    for (final r in itemRows as List) {
      final pid = r['product_id'] as String;
      priceChanges[pid] = (priceChanges[pid] ?? [])
        ..add(r['purchase_price'] as int? ?? 0);
    }

    String highIncrease = '—';
    String highDecrease = '—';
    double maxInc = 0;
    double maxDec = 0;

    for (final entry in priceChanges.entries) {
      final prices = entry.value;
      if (prices.length >= 2) {
        final first = prices.first.toDouble();
        final last = prices.last.toDouble();
        if (first > 0) {
          final change = (last - first) / first * 100;
          if (change > maxInc) {
            maxInc = change;
            highIncrease = entry.key.substring(0, 8);
          }
          if (change < maxDec) {
            maxDec = change;
            highDecrease = entry.key.substring(0, 8);
          }
        }
      }
    }

    final allItems = await _client
        .from('restock_items')
        .select('purchase_price')
        .eq('restocks.organization_id', _orgId);
    final allPrices = (allItems as List)
        .map((r) => r['purchase_price'] as int? ?? 0)
        .where((p) => p > 0)
        .toList();
    final avgPrice = allPrices.isEmpty
        ? 0
        : allPrices.fold<int>(0, (s, p) => s + p) ~/
            allPrices.length;

    return PurchasingAnalytics(
      totalPurchaseValue: totalPurchase,
      purchaseFrequency: (restockRows as List).length,
      avgPurchasePrice: avgPrice,
      highestCostIncrease: highIncrease,
      highestCostDecrease: highDecrease,
      purchaseTrend: trend,
    );
  }

  // ---------------------------------------------------------------------------
  // getPricingAnalytics
  // ---------------------------------------------------------------------------

  @override
  Future<PricingAnalytics> getPricingAnalytics() async {
    final rows = await _client
        .from('products')
        .select('id, name, sell_price, last_buy_price')
        .eq('organization_id', _orgId)
        .eq('is_active', true);

    final margins = (rows as List).map((r) {
      final sell = r['sell_price'] as int? ?? 0;
      final buy = r['last_buy_price'] as int? ?? 0;
      final margin = sell > 0 ? (sell - buy) / sell * 100 : 0.0;
      return ProductMargin(
        productId: r['id'] as String,
        productName: r['name'] as String,
        sellPrice: sell,
        buyPrice: buy,
        margin: margin.toDouble(),
      );
    }).toList();

    final negative =
        margins.where((m) => m.isNegative).toList();
    final missingSell =
        margins.where((m) => m.isMissingSell).toList();
    final missingBuy =
        margins.where((m) => m.isMissingBuy).toList();

    margins.sort((a, b) => b.margin.compareTo(a.margin));
    final highest =
        margins.isNotEmpty ? margins.first : null;
    final lowest =
        margins.isNotEmpty ? margins.last : null;

    return PricingAnalytics(
      highestMargin: highest,
      lowestMargin: lowest,
      negativeMarginProducts: negative,
      missingSellPrice: missingSell,
      missingBuyPrice: missingBuy,
      allMargins: margins,
    );
  }

  // ---------------------------------------------------------------------------
  // getKasbonAnalytics
  // ---------------------------------------------------------------------------

  @override
  Future<KasbonAnalytics> getKasbonAnalytics() async {
    final now = DateTime.now();
    final monthMs = _monthStart(now);

    final allTx = await _client
        .from('debt_transactions')
        .select('customer_id, type, amount, created_at')
        .eq('organization_id', _orgId);

    final balances = <String, int>{};
    final lastDebtDate = <String, int>{};
    int recoveredThisMonth = 0;

    for (final tx in allTx as List) {
      final cid = tx['customer_id'] as String;
      final amt = tx['amount'] as int? ?? 0;
      final ts = tx['created_at'] as int? ?? 0;
      balances[cid] = (balances[cid] ?? 0) +
          (tx['type'] == 'debt' ? amt : -amt);
      if (tx['type'] == 'debt') {
        if (ts > (lastDebtDate[cid] ?? 0))
          lastDebtDate[cid] = ts;
      }
      if (tx['type'] == 'payment' && ts >= monthMs) {
        recoveredThisMonth += amt;
      }
    }

    int totalOutstanding = 0;
    int largest = 0;
    String largestName = '';
    int over30 = 0;
    int over90 = 0;
    int debtCount = 0;

    for (final entry in balances.entries) {
      if (entry.value > 0) {
        totalOutstanding += entry.value;
        debtCount++;
        if (entry.value > largest) {
          largest = entry.value;
          largestName = entry.key.substring(0, 8);
        }
        final lastTs = lastDebtDate[entry.key] ?? 0;
        final ageMs = now.millisecondsSinceEpoch - lastTs;
        final ageDays = ageMs ~/ (1000 * 60 * 60 * 24);
        if (ageDays > 30) over30++;
        if (ageDays > 90) over90++;
      }
    }

    final avgDebt =
        debtCount > 0 ? totalOutstanding ~/ debtCount : 0;

    // Fetch customer name for largest
    if (largestName.length <= 8) {
      try {
        final cidEntry = balances.entries
            .where((e) => e.value == largest)
            .firstOrNull;
        if (cidEntry != null) {
          final cRow = await _client
              .from('customers')
              .select('name')
              .eq('id', cidEntry.key)
              .maybeSingle();
          if (cRow != null) {
            largestName = cRow['name'] as String? ?? largestName;
          }
        }
      } catch (_) {}
    }

    // Aging buckets
    final aging = {
      '0–30 hari': 0,
      '31–60 hari': 0,
      '61–90 hari': 0,
      '90+ hari': 0,
    };
    for (final entry in balances.entries) {
      if (entry.value > 0) {
        final lastTs = lastDebtDate[entry.key] ?? 0;
        final ageDays = (now.millisecondsSinceEpoch - lastTs) ~/
            (1000 * 60 * 60 * 24);
        if (ageDays <= 30) aging['0–30 hari'] = aging['0–30 hari']! + entry.value;
        else if (ageDays <= 60) aging['31–60 hari'] = aging['31–60 hari']! + entry.value;
        else if (ageDays <= 90) aging['61–90 hari'] = aging['61–90 hari']! + entry.value;
        else aging['90+ hari'] = aging['90+ hari']! + entry.value;
      }
    }

    return KasbonAnalytics(
      totalOutstanding: totalOutstanding,
      recoveredThisMonth: recoveredThisMonth,
      averageDebt: avgDebt,
      largestCustomerName: largestName,
      largestCustomerBalance: largest,
      customersOver30Days: over30,
      customersOver90Days: over90,
      agingBuckets: aging,
    );
  }

  // ---------------------------------------------------------------------------
  // getBusinessInsights
  // ---------------------------------------------------------------------------

  @override
  Future<List<BusinessInsight>> getBusinessInsights() async {
    final insights = <BusinessInsight>[];

    // Out of stock
    final outOfStock = await _client
        .from('products')
        .select('id, name')
        .eq('organization_id', _orgId)
        .eq('is_active', true)
        .lte('current_stock', 0);
    final outCount = (outOfStock as List).length;
    if (outCount > 0) {
      insights.add(BusinessInsight(
        id: 'out_of_stock',
        priority: InsightPriority.high,
        title: '$outCount produk kehabisan stok',
        description: 'Segera restock untuk menghindari kehilangan penjualan.',
        actionRoute: '/products',
        actionLabel: 'Lihat Produk',
      ));
    }

    // Low stock
    final lowStock = await _client
        .from('products')
        .select('id, name')
        .eq('organization_id', _orgId)
        .eq('is_active', true)
        .gte('current_stock', 1)
        .lte('current_stock', 3);
    final lowCount = (lowStock as List).length;
    if (lowCount > 0) {
      insights.add(BusinessInsight(
        id: 'low_stock',
        priority: InsightPriority.medium,
        title: '$lowCount produk stok rendah',
        description: 'Stok tersisa 1–3 unit.',
        actionRoute: '/products',
        actionLabel: 'Lihat Produk',
      ));
    }

    // Customers over 90 days
    final now = DateTime.now();
    final since90 = DateTime(now.year, now.month, now.day - 90)
        .millisecondsSinceEpoch;
    final oldDebt = await _client
        .from('debt_transactions')
        .select('customer_id, created_at')
        .eq('organization_id', _orgId)
        .eq('type', 'debt')
        .lt('created_at', since90);
    final oldCustomers =
        (oldDebt as List).map((r) => r['customer_id']).toSet();
    if (oldCustomers.isNotEmpty) {
      insights.add(BusinessInsight(
        id: 'old_debt',
        priority: InsightPriority.high,
        title:
            '${oldCustomers.length} pelanggan belum bayar > 90 hari',
        description:
            'Hutang lama perlu tindak lanjut segera.',
        actionRoute: '/customers',
        actionLabel: 'Lihat Kasbon',
      ));
    }

    // Negative margin products
    final negMargin = await _client
        .from('products')
        .select('name, sell_price, last_buy_price')
        .eq('organization_id', _orgId)
        .eq('is_active', true);
    final negCount = (negMargin as List)
        .where((r) =>
            (r['sell_price'] as int? ?? 0) > 0 &&
            (r['sell_price'] as int) < (r['last_buy_price'] as int? ?? 0))
        .length;
    if (negCount > 0) {
      insights.add(BusinessInsight(
        id: 'negative_margin',
        priority: InsightPriority.high,
        title: '$negCount produk dijual rugi',
        description:
            'Harga jual lebih rendah dari harga beli.',
        actionRoute: '/analytics',
        actionLabel: 'Lihat Harga',
      ));
    }

    // No sales in 7 days
    final since7 = DateTime(now.year, now.month, now.day - 7)
        .millisecondsSinceEpoch;
    final recentSales = await _client
        .from('sales')
        .select('id')
        .eq('organization_id', _orgId)
        .gte('created_at', since7);
    if ((recentSales as List).isEmpty) {
      insights.add(BusinessInsight(
        id: 'no_sales',
        priority: InsightPriority.medium,
        title: 'Tidak ada penjualan 7 hari terakhir',
        description:
            'Periksa apakah Android sudah tersinkronisasi.',
        actionRoute: '/sales',
        actionLabel: 'Lihat Penjualan',
      ));
    }

    // Sort by priority
    insights.sort((a, b) {
      const order = {
        InsightPriority.high: 0,
        InsightPriority.medium: 1,
        InsightPriority.low: 2,
      };
      return order[a.priority]!.compareTo(order[b.priority]!);
    });

    return insights;
  }
}
