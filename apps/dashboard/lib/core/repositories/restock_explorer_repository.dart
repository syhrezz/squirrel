import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/restocks/models/restock_models.dart';

abstract class RestockExplorerRepository {
  Future<RestockPageResult> getRestocks(RestockFilter filter);
  Future<RestockDetail> getRestockDetail(String restockId);
  Future<List<PurchaseHistoryPoint>> getPurchaseHistory(
      String productId);
  Future<PurchaseSummary> getPurchaseSummary(
      RestockFilter filter);
}

class SupabaseRestockExplorerRepository
    implements RestockExplorerRepository {
  SupabaseRestockExplorerRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  // ---------------------------------------------------------------------------
  // getRestocks
  // ---------------------------------------------------------------------------

  @override
  Future<RestockPageResult> getRestocks(
      RestockFilter filter) async {
    // Count
    var countQ = _client
        .from('restocks')
        .select('id')
        .eq('organization_id', _orgId);
    final (fromMs, toMs) = filter.epochRange;
    if (fromMs != null) countQ = countQ.gte('created_at', fromMs);
    if (toMs != null) countQ = countQ.lt('created_at', toMs);
    if (filter.minTotal != null) {
      countQ = countQ.gte('total_amount', filter.minTotal!);
    }
    if (filter.maxTotal != null) {
      countQ = countQ.lte('total_amount', filter.maxTotal!);
    }
    final countRows = await countQ;
    final totalCount = (countRows as List).length;

    // Data
    final sortCol = switch (filter.sortField) {
      RestockSortField.date => 'created_at',
      RestockSortField.total => 'total_amount',
      RestockSortField.itemCount => 'created_at',
    };

    var query = _client
        .from('restocks')
        .select(
            'id, created_at, created_by, device_id, total_amount, synced')
        .eq('organization_id', _orgId);

    if (fromMs != null) query = query.gte('created_at', fromMs);
    if (toMs != null) query = query.lt('created_at', toMs);
    if (filter.minTotal != null) {
      query = query.gte('total_amount', filter.minTotal!);
    }
    if (filter.maxTotal != null) {
      query = query.lte('total_amount', filter.maxTotal!);
    }

    final offset = filter.page * filter.pageSize;
    final rows = await query
        .order(sortCol,
            ascending: filter.sortDir == RestockSortDir.asc)
        .range(offset, offset + filter.pageSize - 1);

    // Item counts
    final ids = (rows as List)
        .map((r) => r['id'] as String)
        .toList();
    final itemCounts = <String, int>{};
    if (ids.isNotEmpty) {
      final countItems = await _client
          .from('restock_items')
          .select('restock_id')
          .inFilter('restock_id', ids);
      for (final r in countItems as List) {
        final rid = r['restock_id'] as String;
        itemCounts[rid] = (itemCounts[rid] ?? 0) + 1;
      }
    }

    // Search filter (client-side for simplicity — product name search)
    final items = rows.map((r) {
      final id = r['id'] as String;
      return RestockExplorerItem(
        id: id,
        restockNumber:
            'RST-${id.substring(0, 8).toUpperCase()}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int),
        createdBy: r['created_by'] as String? ?? '',
        deviceId: r['device_id'] as String? ?? '',
        totalAmount: r['total_amount'] as int? ?? 0,
        itemCount: itemCounts[id] ?? 0,
        synced: r['synced'] as bool? ?? false,
      );
    }).toList();

    return RestockPageResult(
      items: items,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
    );
  }

  // ---------------------------------------------------------------------------
  // getRestockDetail
  // ---------------------------------------------------------------------------

  @override
  Future<RestockDetail> getRestockDetail(
      String restockId) async {
    final row = await _client
        .from('restocks')
        .select()
        .eq('id', restockId)
        .eq('organization_id', _orgId)
        .single();

    final itemRows = await _client
        .from('restock_items')
        .select(
            'id, product_id, quantity, purchase_price, subtotal')
        .eq('restock_id', restockId);

    final productIds = (itemRows as List)
        .map((r) => r['product_id'] as String)
        .toSet()
        .toList();

    final productData = <String, Map<String, dynamic>>{};
    if (productIds.isNotEmpty) {
      final pRows = await _client
          .from('products')
          .select(
              'id, name, inventory_unit, purchase_unit, purchase_conversion')
          .inFilter('id', productIds);
      for (final r in pRows as List) {
        productData[r['id'] as String] =
            r as Map<String, dynamic>;
      }
    }

    final items = itemRows.map((r) {
      final pid = r['product_id'] as String;
      final pd = productData[pid] ?? {};
      return RestockItemDetail(
        id: r['id'] as String,
        productId: pid,
        productName: pd['name'] as String? ??
            pid.substring(0, 8),
        inventoryUnit:
            pd['inventory_unit'] as String? ?? 'pcs',
        purchaseUnit:
            pd['purchase_unit'] as String? ?? 'pcs',
        purchaseConversion:
            pd['purchase_conversion'] as int? ?? 1,
        quantity: r['quantity'] as int? ?? 0,
        purchasePrice: r['purchase_price'] as int? ?? 0,
        subtotal: r['subtotal'] as int? ?? 0,
      );
    }).toList();

    final id = row['id'] as String;
    return RestockDetail(
      id: id,
      restockNumber: 'RST-${id.substring(0, 8).toUpperCase()}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int),
      createdBy: row['created_by'] as String? ?? '',
      deviceId: row['device_id'] as String? ?? '',
      totalAmount: row['total_amount'] as int? ?? 0,
      synced: row['synced'] as bool? ?? false,
      items: items,
    );
  }

  // ---------------------------------------------------------------------------
  // getPurchaseHistory
  // ---------------------------------------------------------------------------

  @override
  Future<List<PurchaseHistoryPoint>> getPurchaseHistory(
      String productId) async {
    final rows = await _client
        .from('restock_items')
        .select(
            'restock_id, quantity, purchase_price, restocks!inner(created_at, organization_id)')
        .eq('product_id', productId)
        .eq('restocks.organization_id', _orgId)
        .order('restocks(created_at)', ascending: true);

    final points = <PurchaseHistoryPoint>[];
    int? prevPrice;
    for (final r in rows as List) {
      final nested = r['restocks'];
      final ts = (nested is Map
              ? nested['created_at']
              : null) as int? ??
          0;
      final price = r['purchase_price'] as int? ?? 0;
      points.add(PurchaseHistoryPoint(
        date: DateTime.fromMillisecondsSinceEpoch(ts),
        purchasePrice: price,
        quantity: r['quantity'] as int? ?? 0,
        restockId: r['restock_id'] as String,
        prevPrice: prevPrice,
      ));
      prevPrice = price;
    }
    return points.reversed.toList(); // newest first
  }

  // ---------------------------------------------------------------------------
  // getPurchaseSummary
  // ---------------------------------------------------------------------------

  @override
  Future<PurchaseSummary> getPurchaseSummary(
      RestockFilter filter) async {
    var query = _client
        .from('restocks')
        .select('id, total_amount')
        .eq('organization_id', _orgId);

    final (fromMs, toMs) = filter.epochRange;
    if (fromMs != null) query = query.gte('created_at', fromMs);
    if (toMs != null) query = query.lt('created_at', toMs);

    final rows = await query;
    final rList = rows as List;
    if (rList.isEmpty) {
      return const PurchaseSummary(
        totalRestocks: 0,
        totalSpent: 0,
        avgPerRestock: 0,
        highestItem: '—',
        lowestItem: '—',
        priceIncreases: 0,
        priceDecreases: 0,
      );
    }

    final totalSpent = rList.fold<int>(
        0, (s, r) => s + (r['total_amount'] as int? ?? 0));
    final avg = totalSpent ~/ rList.length;

    // Get item price changes (last 30 days)
    final since30 = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    final itemRows = await _client
        .from('restock_items')
        .select(
            'product_id, purchase_price, restocks!inner(created_at, organization_id)')
        .eq('restocks.organization_id', _orgId)
        .gte('restocks.created_at', since30)
        .order('restocks(created_at)', ascending: true);

    // Group by product — detect price changes
    final productPrices = <String, List<int>>{};
    String highestProduct = '—';
    int highestPrice = 0;
    String lowestProduct = '—';
    int lowestPrice = 999999999;

    for (final r in itemRows as List) {
      final pid = r['product_id'] as String;
      final price = r['purchase_price'] as int? ?? 0;
      productPrices[pid] = (productPrices[pid] ?? [])
        ..add(price);
      if (price > highestPrice) {
        highestPrice = price;
        highestProduct = pid.substring(0, 8);
      }
      if (price < lowestPrice && price > 0) {
        lowestPrice = price;
        lowestProduct = pid.substring(0, 8);
      }
    }

    // Fetch product names for highest/lowest
    final pidsToFetch = <String>{};
    if (highestProduct.length <= 8) pidsToFetch.add(highestProduct);
    if (lowestProduct.length <= 8) pidsToFetch.add(lowestProduct);

    int increases = 0;
    int decreases = 0;
    for (final prices in productPrices.values) {
      if (prices.length >= 2) {
        final first = prices.first;
        final last = prices.last;
        if (last > first) increases++;
        if (last < first) decreases++;
      }
    }

    return PurchaseSummary(
      totalRestocks: rList.length,
      totalSpent: totalSpent,
      avgPerRestock: avg,
      highestItem: highestProduct,
      lowestItem: lowestProduct,
      priceIncreases: increases,
      priceDecreases: decreases,
    );
  }
}
