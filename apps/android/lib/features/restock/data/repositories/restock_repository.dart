import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../../../features/sync/data/repositories/sync_repository.dart';
import '../../models/shopping_item.dart';

/// Abstract interface for restock persistence.
/// Append-only: no update or delete methods.
abstract class RestockRepository {
  Future<Restock> createRestock({required List<ShoppingItem> items});
}

/// Drift (SQLite) implementation of [RestockRepository].
///
/// v2: Stock addition now uses [ShoppingItem.inventoryStockAdded] which is
/// quantity × purchaseConversion. Operator records purchase units;
/// system converts to inventory units automatically.
///
/// Example: Operator buys 2 Dus of Snack Chiki (1 Dus = 10 pcs)
///   → inventoryStockAdded = 2 × 10 = 20 pcs added to stock
class DriftRestockRepository implements RestockRepository {
  const DriftRestockRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncRepository _sync;

  @override
  Future<Restock> createRestock({
    required List<ShoppingItem> items,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final restockId = UuidUtil.generate();
    final totalAmount = items.fold<int>(0, (sum, i) => sum + i.subtotal);

    final result = await _db.transaction<Restock>(() async {
      // 1. Insert restock header
      await _db.into(_db.restocks).insert(RestocksCompanion.insert(
        id: restockId,
        createdAt: now,
        createdBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        totalAmount: totalAmount,
        synced: const Value(false),
      ));

      for (final item in items) {
        final itemId = UuidUtil.generate();

        // 2. Insert restock item — quantity stored in PURCHASE units
        //    (e.g. 2 Dus), not inventory units. Historical record stays clean.
        await _db.into(_db.restockItems).insert(RestockItemsCompanion.insert(
          id: itemId,
          restockId: restockId,
          productId: item.productId,
          quantity: item.quantity,
          purchasePrice: item.purchasePrice,
          subtotal: item.subtotal,
        ));

        // 3. Increment stock using INVENTORY units.
        //    inventoryStockAdded = quantity × purchaseConversion
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingle();

        final newStock =
            product.currentStock + item.inventoryStockAdded;

        await (_db.update(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .write(ProductsCompanion(
          currentStock: Value(newStock),
          lastBuyPrice: Value(item.purchasePrice),
          updatedAt: Value(now),
          updatedBy: Value(kDevUser.id),
          synced: const Value(false),
        ));

        // 4. Append stock movement in inventory units
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: UuidUtil.generate(),
                productId: item.productId,
                quantityChange: item.inventoryStockAdded,
                sourceType: 'restock',
                sourceId: restockId,
                createdAt: now,
                createdBy: kDevUser.id,
                deviceId: kDevUser.deviceId,
                synced: const Value(false),
              ),
            );
      }

      return (_db.select(_db.restocks)
            ..where((r) => r.id.equals(restockId)))
          .getSingle();
    });

    // Enqueue sync.
    await _sync.enqueueCreate(tableName: 'restocks', recordId: restockId);
    final restockItems = await (_db.select(_db.restockItems)
          ..where((ri) => ri.restockId.equals(restockId)))
        .get();
    for (final ri in restockItems) {
      await _sync.enqueueCreate(tableName: 'restock_items', recordId: ri.id);
    }
    for (final item in items) {
      await _sync.enqueueUpdate(
          tableName: 'products', recordId: item.productId);
      final movements = await (_db.select(_db.stockMovements)
            ..where((sm) =>
                sm.sourceId.equals(restockId) &
                sm.productId.equals(item.productId)))
          .get();
      for (final mv in movements) {
        await _sync.enqueueCreate(
            tableName: 'stock_movements', recordId: mv.id);
      }
    }

    return result;
  }
}
