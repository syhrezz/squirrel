import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../models/shopping_item.dart';

/// Abstract interface for restock persistence.
///
/// Append-only: no update or delete methods.
abstract class RestockRepository {
  /// Persists a complete shopping trip atomically.
  ///
  /// In a single database transaction:
  /// 1. Inserts the [Restocks] row.
  /// 2. Inserts all [RestockItems] rows.
  /// 3. Updates [Products.currentStock] += quantity for each item.
  /// 4. Updates [Products.lastBuyPrice] = purchasePrice for each item.
  /// 5. Inserts a [StockMovements] row for each item.
  ///
  /// If any step fails, the entire transaction is rolled back.
  Future<Restock> createRestock({
    required List<ShoppingItem> items,
  });
}

/// Drift (SQLite) implementation of [RestockRepository].
class DriftRestockRepository implements RestockRepository {
  const DriftRestockRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Restock> createRestock({
    required List<ShoppingItem> items,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final restockId = UuidUtil.generate();
    final totalAmount = items.fold<int>(0, (sum, i) => sum + i.subtotal);

    return _db.transaction<Restock>(() async {
      // 1. Insert restock header
      await _db.into(_db.restocks).insert(
            RestocksCompanion.insert(
              id: restockId,
              createdAt: now,
              createdBy: kDevUser.id,
              deviceId: kDevUser.deviceId,
              totalAmount: totalAmount,
              synced: const Value(false),
            ),
          );

      for (final item in items) {
        final itemId = UuidUtil.generate();

        // 2. Insert restock item (purchase price snapshotted at time of purchase)
        await _db.into(_db.restockItems).insert(
              RestockItemsCompanion.insert(
                id: itemId,
                restockId: restockId,
                productId: item.productId,
                quantity: item.quantity,
                purchasePrice: item.purchasePrice,
                subtotal: item.subtotal,
              ),
            );

        // 3. Read current stock then increment atomically within the transaction.
        // Drift's companion.write() requires plain int values, not expressions,
        // so we read-then-write inside the transaction for correctness.
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingle();

        await (_db.update(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .write(
          ProductsCompanion(
            currentStock: Value(product.currentStock + item.quantity),
            lastBuyPrice: Value(item.purchasePrice),
            updatedAt: Value(now),
            updatedBy: Value(kDevUser.id),
            synced: const Value(false),
          ),
        );

        // 4. Append stock movement (positive quantity = stock in)
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: UuidUtil.generate(),
                productId: item.productId,
                quantityChange: item.quantity,
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
  }
}
