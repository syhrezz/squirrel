import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../../../features/sync/data/repositories/sync_repository.dart';
import '../../models/cart_item.dart';

/// Abstract interface for sale persistence.
/// Append-only: no update or delete methods.
abstract class SaleRepository {
  Future<Sale> createSale({
    required List<CartItem> items,
    required int amountPaid,
  });
}

/// Drift (SQLite) implementation of [SaleRepository].
///
/// v2: Stock deduction now uses [CartItem.totalInventoryDeduction] instead of
/// [CartItem.quantity]. This means selling 1 × "500 gram option" correctly
/// deducts 500 grams from stock, not 1 unit.
class DriftSaleRepository implements SaleRepository {
  const DriftSaleRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncRepository _sync;

  @override
  Future<Sale> createSale({
    required List<CartItem> items,
    required int amountPaid,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final saleId = UuidUtil.generate();
    final totalAmount = items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final changeAmount = amountPaid - totalAmount;

    final result = await _db.transaction<Sale>(() async {
      // 1. Insert sale header
      await _db.into(_db.sales).insert(SalesCompanion.insert(
        id: saleId,
        createdAt: now,
        createdBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        synced: const Value(false),
      ));

      for (final item in items) {
        final itemId = UuidUtil.generate();

        // 2. Insert sale item — quantity = number of options sold,
        //    sellingPrice = price of that option (may be manually edited)
        await _db.into(_db.saleItems).insert(SaleItemsCompanion.insert(
          id: itemId,
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          sellingPrice: item.sellingPrice,
          subtotal: item.subtotal,
        ));

        // 3. Decrement product stock using INVENTORY units.
        //    totalInventoryDeduction = item.quantity × inventoryQuantityPerUnit
        //    Example: 2 × "500 gram" option → deduct 1000 grams
        final product = await (_db.select(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .getSingle();

        final newStock =
            product.currentStock - item.totalInventoryDeduction;

        await (_db.update(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .write(ProductsCompanion(
          currentStock: Value(newStock),
          updatedAt: Value(now),
          updatedBy: Value(kDevUser.id),
          synced: const Value(false),
        ));

        // 4. Insert stock movement — quantity_change in inventory units
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: UuidUtil.generate(),
                productId: item.productId,
                quantityChange: -item.totalInventoryDeduction,
                sourceType: 'sale',
                sourceId: saleId,
                createdAt: now,
                createdBy: kDevUser.id,
                deviceId: kDevUser.deviceId,
                synced: const Value(false),
              ),
            );
      }

      return (_db.select(_db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();
    });

    // Enqueue sync after transaction commits.
    await _sync.enqueueCreate(tableName: 'sales', recordId: saleId);
    final saleItems = await (_db.select(_db.saleItems)
          ..where((si) => si.saleId.equals(saleId)))
        .get();
    for (final si in saleItems) {
      await _sync.enqueueCreate(tableName: 'sale_items', recordId: si.id);
    }
    for (final item in items) {
      final movements = await (_db.select(_db.stockMovements)
            ..where((sm) =>
                sm.sourceId.equals(saleId) &
                sm.productId.equals(item.productId)))
          .get();
      for (final mv in movements) {
        await _sync.enqueueCreate(
            tableName: 'stock_movements', recordId: mv.id);
      }
      await _sync.enqueueUpdate(
          tableName: 'products', recordId: item.productId);
    }

    return result;
  }
}
