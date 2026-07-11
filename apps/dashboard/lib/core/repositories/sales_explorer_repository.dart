import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/sales/models/sales_models.dart';

abstract class SalesExplorerRepository {
  Future<SalesPageResult> getSales(SalesFilter filter);
  Future<SaleDetail> getSaleDetail(String saleId);
  Future<int> getSalesCount(SalesFilter filter);
}

class SupabaseSalesExplorerRepository
    implements SalesExplorerRepository {
  SupabaseSalesExplorerRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  @override
  Future<SalesPageResult> getSales(SalesFilter filter) async {
    final totalCount = await getSalesCount(filter);
    final offset = filter.page * filter.pageSize;

    final sortColumn = switch (filter.sortField) {
      SalesSortField.date => 'created_at',
      SalesSortField.total => 'total_amount',
      SalesSortField.itemCount => 'created_at',
    };
    final ascending =
        filter.sortDirection == SortDirection.asc;

    var query = _client
        .from('sales')
        .select(
            'id, created_at, created_by, device_id, total_amount, amount_paid, change_amount, synced')
        .eq('organization_id', _orgId);

    final (fromMs, toMs) = filter.epochRange;
    if (fromMs != null) {
      query = query.gte('created_at', fromMs);
    }
    if (toMs != null) {
      query = query.lt('created_at', toMs);
    }
    if (filter.minTotal != null) {
      query = query.gte('total_amount', filter.minTotal!);
    }
    if (filter.maxTotal != null) {
      query = query.lte('total_amount', filter.maxTotal!);
    }
    if (filter.search.isNotEmpty) {
      query = query.ilike(
          'created_by', '%${filter.search}%');
    }

    final rows = await query
        .order(sortColumn, ascending: ascending)
        .range(offset, offset + filter.pageSize - 1);

    final saleIds = (rows as List)
        .map((r) => r['id'] as String)
        .toList();

    final itemCounts = <String, int>{};
    if (saleIds.isNotEmpty) {
      final countRows = await _client
          .from('sale_items')
          .select('sale_id')
          .inFilter('sale_id', saleIds);
      for (final r in countRows as List) {
        final sid = r['sale_id'] as String;
        itemCounts[sid] = (itemCounts[sid] ?? 0) + 1;
      }
    }

    final items = rows.map((r) {
      final id = r['id'] as String;
      final ts = r['created_at'] as int;
      return SalesListItem(
        id: id,
        invoiceNumber:
            'INV-${id.substring(0, 8).toUpperCase()}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
        createdBy: r['created_by'] as String? ?? '',
        deviceId: r['device_id'] as String? ?? '',
        totalAmount: r['total_amount'] as int? ?? 0,
        itemCount: itemCounts[id] ?? 0,
        synced: r['synced'] as bool? ?? false,
      );
    }).toList();

    return SalesPageResult(
      items: items,
      totalCount: totalCount,
      page: filter.page,
      pageSize: filter.pageSize,
    );
  }

  @override
  Future<SaleDetail> getSaleDetail(String saleId) async {
    final saleRow = await _client
        .from('sales')
        .select()
        .eq('id', saleId)
        .eq('organization_id', _orgId)
        .single();

    final itemRows = await _client
        .from('sale_items')
        .select(
            'id, product_id, quantity, selling_price, subtotal')
        .eq('sale_id', saleId);

    final productIds = (itemRows as List)
        .map((r) => r['product_id'] as String)
        .toSet()
        .toList();

    final productNames = <String, String>{};
    if (productIds.isNotEmpty) {
      final productRows = await _client
          .from('products')
          .select('id, name')
          .inFilter('id', productIds);
      for (final r in productRows as List) {
        productNames[r['id'] as String] =
            r['name'] as String;
      }
    }

    final items = itemRows.map((r) {
      final pid = r['product_id'] as String;
      return SaleItemDetail(
        id: r['id'] as String,
        productId: pid,
        productName:
            productNames[pid] ?? pid.substring(0, 8),
        quantity: r['quantity'] as int? ?? 0,
        sellingPrice: r['selling_price'] as int? ?? 0,
        subtotal: r['subtotal'] as int? ?? 0,
      );
    }).toList();

    final id = saleRow['id'] as String;
    final ts = saleRow['created_at'] as int;

    return SaleDetail(
      id: id,
      invoiceNumber:
          'INV-${id.substring(0, 8).toUpperCase()}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
      createdBy: saleRow['created_by'] as String? ?? '',
      deviceId: saleRow['device_id'] as String? ?? '',
      totalAmount: saleRow['total_amount'] as int? ?? 0,
      amountPaid: saleRow['amount_paid'] as int? ?? 0,
      changeAmount: saleRow['change_amount'] as int? ?? 0,
      synced: saleRow['synced'] as bool? ?? false,
      items: items,
    );
  }

  @override
  Future<int> getSalesCount(SalesFilter filter) async {
    var query = _client
        .from('sales')
        .select('id')
        .eq('organization_id', _orgId);

    final (fromMs, toMs) = filter.epochRange;
    if (fromMs != null) query = query.gte('created_at', fromMs);
    if (toMs != null) query = query.lt('created_at', toMs);
    if (filter.minTotal != null) {
      query = query.gte('total_amount', filter.minTotal!);
    }
    if (filter.maxTotal != null) {
      query = query.lte('total_amount', filter.maxTotal!);
    }
    if (filter.search.isNotEmpty) {
      query = query.ilike('created_by', '%${filter.search}%');
    }

    final rows = await query;
    return (rows as List).length;
  }
}
