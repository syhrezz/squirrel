import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/products/models/product_models.dart';

abstract class ProductExplorerRepository {
  Future<ProductPageResult> getProducts(ProductFilter filter);
  Future<ProductExplorerDetail> getProductDetail(String productId);
  Future<List<RecentProductSale>> getRecentSales(String productId,
      {int limit = 20});
  Future<List<RecentProductRestock>> getRecentRestocks(
      String productId,
      {int limit = 20});
  Future<List<InventoryTimelinePoint>> getInventoryTimeline(
      String productId);
}

class SupabaseProductExplorerRepository
    implements ProductExplorerRepository {
  SupabaseProductExplorerRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  // ---------------------------------------------------------------------------
  // getProducts — paginated list
  // ---------------------------------------------------------------------------

  @override
  Future<ProductPageResult> getProducts(
      ProductFilter filter) async {
    // Count query
    var countQ = _client
        .from('products')
        .select('id')
        .eq('organization_id', _orgId);

    if (filter.status == ProductStatusFilter.active) {
      countQ = countQ.eq('is_active', true);
    } else if (filter.status == ProductStatusFilter.inactive) {
      countQ = countQ.eq('is_active', false);
    }
    if (filter.category.isNotEmpty) {
      countQ = countQ.eq('category', filter.category);
    }
    if (filter.search.isNotEmpty) {
      countQ =
          countQ.ilike('name', '%${filter.search}%');
    }
    if (filter.stockFilter == ProductStockFilter.outOfStock) {
      countQ = countQ.lte('current_stock', 0);
    } else if (filter.stockFilter ==
        ProductStockFilter.lowStock) {
      countQ = countQ
          .gte('current_stock', 1)
          .lte('current_stock', 3);
    }

    final countRows = await countQ;
    final totalCount = (countRows as List).length;

    // Data query
    final sortCol = switch (filter.sortField) {
      ProductSortField.name => 'name',
      ProductSortField.stock => 'current_stock',
      ProductSortField.updatedAt => 'updated_at',
      ProductSortField.sellPrice => 'sell_price',
    };

    var query = _client
        .from('products')
        .select(
            'id, name, category, current_stock, inventory_unit, purchase_unit, purchase_conversion, sell_price, last_buy_price, is_active, updated_at')
        .eq('organization_id', _orgId);

    if (filter.status == ProductStatusFilter.active) {
      query = query.eq('is_active', true);
    } else if (filter.status == ProductStatusFilter.inactive) {
      query = query.eq('is_active', false);
    }
    if (filter.category.isNotEmpty) {
      query = query.eq('category', filter.category);
    }
    if (filter.search.isNotEmpty) {
      query = query.ilike('name', '%${filter.search}%');
    }
    if (filter.stockFilter == ProductStockFilter.outOfStock) {
      query = query.lte('current_stock', 0);
    } else if (filter.stockFilter ==
        ProductStockFilter.lowStock) {
      query = query
          .gte('current_stock', 1)
          .lte('current_stock', 3);
    }

    final offset = filter.page * filter.pageSize;
    final rows = await query
        .order(sortCol, ascending: filter.sortAscending)
        .range(offset, offset + filter.pageSize - 1);

    final items = (rows as List).map((r) {
      final ts = r['updated_at'] as int? ??
          DateTime.now().millisecondsSinceEpoch;
      return ProductExplorerItem(
        id: r['id'] as String,
        name: r['name'] as String,
        category: r['category'] as String? ?? 'lainnya',
        currentStock: r['current_stock'] as int? ?? 0,
        inventoryUnit: r['inventory_unit'] as String? ?? 'pcs',
        purchaseUnit: r['purchase_unit'] as String? ?? 'pcs',
        purchaseConversion:
            r['purchase_conversion'] as int? ?? 1,
        sellPrice: r['sell_price'] as int? ?? 0,
        lastBuyPrice: r['last_buy_price'] as int? ?? 0,
        isActive: r['is_active'] as bool? ?? true,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    }).toList();

    return ProductPageResult(
      items: items,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
    );
  }

  // ---------------------------------------------------------------------------
  // getProductDetail
  // ---------------------------------------------------------------------------

  @override
  Future<ProductExplorerDetail> getProductDetail(
      String productId) async {
    final row = await _client
        .from('products')
        .select()
        .eq('id', productId)
        .eq('organization_id', _orgId)
        .single();

    // Selling options
    final optionRows = await _client
        .from('product_selling_options')
        .select('id, display_name, quantity, selling_price, is_active')
        .eq('product_id', productId)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    final options = (optionRows as List).map((r) {
      return SellingOptionItem(
        id: r['id'] as String,
        displayName: r['display_name'] as String,
        quantity: r['quantity'] as int? ?? 0,
        sellingPrice: r['selling_price'] as int? ?? 0,
        isActive: r['is_active'] as bool? ?? true,
      );
    }).toList();

    // Last restock
    final restockRows = await _client
        .from('restock_items')
        .select('created_at:restocks(created_at)')
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(1);

    DateTime? lastRestockDate;
    if ((restockRows as List).isNotEmpty) {
      final nested = restockRows.first['created_at'];
      if (nested is Map) {
        final ts = nested['created_at'] as int?;
        if (ts != null) {
          lastRestockDate =
              DateTime.fromMillisecondsSinceEpoch(ts);
        }
      }
    }

    // 30-day sales summary
    final since30 = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;

    final saleItemRows = await _client
        .from('sale_items')
        .select(
            'quantity, subtotal, sales!inner(created_at, organization_id)')
        .eq('product_id', productId)
        .eq('sales.organization_id', _orgId)
        .gte('sales.created_at', since30);

    int unitsSold = 0;
    int revenue = 0;
    DateTime? lastSaleDate;
    for (final r in saleItemRows as List) {
      unitsSold += r['quantity'] as int? ?? 0;
      revenue += r['subtotal'] as int? ?? 0;
      final nested = r['sales'];
      if (nested is Map) {
        final ts = nested['created_at'] as int?;
        if (ts != null) {
          final dt =
              DateTime.fromMillisecondsSinceEpoch(ts);
          if (lastSaleDate == null ||
              dt.isAfter(lastSaleDate)) {
            lastSaleDate = dt;
          }
        }
      }
    }

    final updTs = row['updated_at'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final crTs = row['created_at'] as int? ??
        DateTime.now().millisecondsSinceEpoch;

    return ProductExplorerDetail(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String? ?? 'lainnya',
      isActive: row['is_active'] as bool? ?? true,
      inventoryUnit:
          row['inventory_unit'] as String? ?? 'pcs',
      purchaseUnit:
          row['purchase_unit'] as String? ?? 'pcs',
      purchaseConversion:
          row['purchase_conversion'] as int? ?? 1,
      currentStock: row['current_stock'] as int? ?? 0,
      sellPrice: row['sell_price'] as int? ?? 0,
      lastBuyPrice: row['last_buy_price'] as int? ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updTs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(crTs),
      sellingOptions: options,
      lastRestockDate: lastRestockDate,
      lastSaleDate: lastSaleDate,
      unitsSold30d: unitsSold,
      revenue30d: revenue,
    );
  }

  // ---------------------------------------------------------------------------
  // getRecentSales
  // ---------------------------------------------------------------------------

  @override
  Future<List<RecentProductSale>> getRecentSales(
      String productId,
      {int limit = 20}) async {
    final rows = await _client
        .from('sale_items')
        .select(
            'sale_id, quantity, selling_price, subtotal, sales!inner(created_at, organization_id)')
        .eq('product_id', productId)
        .eq('sales.organization_id', _orgId)
        .order('sales(created_at)', ascending: false)
        .limit(limit);

    return (rows as List).map((r) {
      final nested = r['sales'];
      final ts = (nested is Map
              ? nested['created_at']
              : null) as int? ??
          0;
      return RecentProductSale(
        saleId: r['sale_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(ts),
        quantity: r['quantity'] as int? ?? 0,
        sellingPrice: r['selling_price'] as int? ?? 0,
        subtotal: r['subtotal'] as int? ?? 0,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // getRecentRestocks
  // ---------------------------------------------------------------------------

  @override
  Future<List<RecentProductRestock>> getRecentRestocks(
      String productId,
      {int limit = 20}) async {
    final rows = await _client
        .from('restock_items')
        .select(
            'restock_id, quantity, purchase_price, subtotal, restocks!inner(created_at, organization_id)')
        .eq('product_id', productId)
        .eq('restocks.organization_id', _orgId)
        .order('restocks(created_at)', ascending: false)
        .limit(limit);

    return (rows as List).map((r) {
      final nested = r['restocks'];
      final ts = (nested is Map
              ? nested['created_at']
              : null) as int? ??
          0;
      return RecentProductRestock(
        restockId: r['restock_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(ts),
        quantity: r['quantity'] as int? ?? 0,
        purchasePrice: r['purchase_price'] as int? ?? 0,
        subtotal: r['subtotal'] as int? ?? 0,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // getInventoryTimeline
  // ---------------------------------------------------------------------------

  @override
  Future<List<InventoryTimelinePoint>> getInventoryTimeline(
      String productId) async {
    final since90 = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final rows = await _client
        .from('stock_movements')
        .select(
            'quantity_change, source_type, created_at')
        .eq('product_id', productId)
        .eq('organization_id', _orgId)
        .gte('created_at', since90)
        .order('created_at', ascending: true);

    if ((rows as List).isEmpty) return [];

    // Get current stock and work backwards
    final productRow = await _client
        .from('products')
        .select('current_stock')
        .eq('id', productId)
        .single();
    int runningStock =
        productRow['current_stock'] as int? ?? 0;

    // Process movements backwards to reconstruct timeline
    final allMovements = rows
        .map((r) => (
              date: DateTime.fromMillisecondsSinceEpoch(
                  r['created_at'] as int),
              change: r['quantity_change'] as int? ?? 0,
              type: r['source_type'] as String? ?? '',
            ))
        .toList();

    // Build timeline forwards
    int stockAtStart = runningStock -
        allMovements.fold<int>(
            0, (sum, m) => sum + m.change);

    final points = <InventoryTimelinePoint>[];
    int stock = stockAtStart;
    for (final m in allMovements) {
      stock += m.change;
      points.add(InventoryTimelinePoint(
        date: m.date,
        stock: stock,
        changeType: m.type,
        changeAmount: m.change,
      ));
    }

    return points;
  }
}
