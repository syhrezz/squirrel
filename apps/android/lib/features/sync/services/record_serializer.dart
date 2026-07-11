import '../../../core/config/env.dart';
import '../../../core/database/app_database.dart';

/// Fetches a full business record from its home table and returns it as a
/// plain [Map<String, dynamic>] suitable for sending to Supabase.
///
/// Every payload includes [organization_id] from [AppEnv.organizationId].
/// This satisfies the multi-tenancy RLS requirement on all Supabase tables.
///
/// Rules:
/// - Every integer timestamp stays as int (epoch ms).
/// - Booleans stay as bool.
/// - Null fields are included (Supabase sets the column to NULL).
/// - If a record was deleted before the push runs, returns null.
///   The caller marks that queue entry as success (nothing to push).
class RecordSerializer {
  const RecordSerializer(this._db);

  final AppDatabase _db;

  static const String _orgId = AppEnv.organizationId;

  Future<Map<String, dynamic>?> serialize(
    String tableName,
    String recordId,
  ) async {
    switch (tableName) {
      case 'products':
        return _product(recordId);
      case 'product_selling_options':
        return _sellingOption(recordId);
      case 'sales':
        return _sale(recordId);
      case 'sale_items':
        return _saleItem(recordId);
      case 'restocks':
        return _restock(recordId);
      case 'restock_items':
        return _restockItem(recordId);
      case 'customers':
        return _customer(recordId);
      case 'debt_transactions':
        return _debtTransaction(recordId);
      case 'stock_movements':
        return _stockMovement(recordId);
      default:
        return const {};
    }
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _product(String id) async {
    final row = await (_db.select(_db.products)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'name': row.name,
      'unit': row.unit,
      'custom_unit': row.customUnit,
      'sell_price': row.sellPrice,
      'last_buy_price': row.lastBuyPrice,
      'current_stock': row.currentStock,
      'is_active': row.isActive,
      'category': row.category,
      'inventory_unit': row.inventoryUnit,
      'purchase_unit': row.purchaseUnit,
      'purchase_conversion': row.purchaseConversion,
      'allow_manual_price': row.allowManualPrice,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'created_by': row.createdBy,
      'updated_by': row.updatedBy,
      'device_id': row.deviceId,
    };
  }

  // ---------------------------------------------------------------------------
  // Product selling options
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _sellingOption(String id) async {
    final row = await (_db.select(_db.productSellingOptions)
          ..where((o) => o.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'product_id': row.productId,
      'display_name': row.displayName,
      'quantity': row.quantity,
      'selling_price': row.sellingPrice,
      'display_order': row.displayOrder,
      'is_active': row.isActive,
    };
  }

  // ---------------------------------------------------------------------------
  // Sales
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _sale(String id) async {
    final row = await (_db.select(_db.sales)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'created_at': row.createdAt,
      'created_by': row.createdBy,
      'device_id': row.deviceId,
      'total_amount': row.totalAmount,
      'amount_paid': row.amountPaid,
      'change_amount': row.changeAmount,
    };
  }

  // ---------------------------------------------------------------------------
  // Sale items
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _saleItem(String id) async {
    final row = await (_db.select(_db.saleItems)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'sale_id': row.saleId,
      'product_id': row.productId,
      'quantity': row.quantity,
      'selling_price': row.sellingPrice,
      'subtotal': row.subtotal,
    };
  }

  // ---------------------------------------------------------------------------
  // Restocks
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _restock(String id) async {
    final row = await (_db.select(_db.restocks)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'created_at': row.createdAt,
      'created_by': row.createdBy,
      'device_id': row.deviceId,
      'total_amount': row.totalAmount,
    };
  }

  // ---------------------------------------------------------------------------
  // Restock items
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _restockItem(String id) async {
    final row = await (_db.select(_db.restockItems)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'restock_id': row.restockId,
      'product_id': row.productId,
      'quantity': row.quantity,
      'purchase_price': row.purchasePrice,
      'subtotal': row.subtotal,
    };
  }

  // ---------------------------------------------------------------------------
  // Customers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _customer(String id) async {
    final row = await (_db.select(_db.customers)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'name': row.name,
      'phone': row.phone,
      'is_active': row.isActive,
      'created_at': row.createdAt,
      'updated_at': row.updatedAt,
      'created_by': row.createdBy,
      'updated_by': row.updatedBy,
    };
  }

  // ---------------------------------------------------------------------------
  // Debt transactions
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _debtTransaction(String id) async {
    final row = await (_db.select(_db.debtTransactions)
          ..where((d) => d.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'customer_id': row.customerId,
      'type': row.type,
      'amount': row.amount,
      'note': row.note,
      'created_at': row.createdAt,
      'created_by': row.createdBy,
    };
  }

  // ---------------------------------------------------------------------------
  // Stock movements
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _stockMovement(String id) async {
    final row = await (_db.select(_db.stockMovements)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'organization_id': _orgId,
      'product_id': row.productId,
      'quantity_change': row.quantityChange,
      'source_type': row.sourceType,
      'source_id': row.sourceId,
      'created_at': row.createdAt,
      'created_by': row.createdBy,
      'device_id': row.deviceId,
    };
  }
}
