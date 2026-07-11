import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../models/cart_item.dart';

/// Abstract interface for sale persistence.
///
/// Append-only: no update or delete methods.
abstract class SaleRepository {
  /// Persists a complete sale atomically.
  ///
  /// In a single database transaction:
  /// 1. Inserts the [Sales] row.
  /// 2. Inserts all [SaleItems] rows.
  /// 3. Decrements [Products.currentStock] for each item.
  /// 4. Inserts a [StockMovements] row for each item.
  ///
  /// If any step fails, the entire transaction is rolled back.
  Future<Sale> createSale({
    required List<CartItem> items,
    required int amountPaid,
  });
}

/// Drift (SQLite) implementation of [SaleRepository].
class DriftSaleRepository implements SaleRepository {
  const DriftSaleRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Sale> createSale({
    required List<CartItem> items,
    required int amountPaid,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final saleId = UuidUtil.generate();
    final totalAmount = items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final changeAmount = amountPaid - totalAmount;

    return _db.transaction<Sale>(() async {
      // 1. Insert sale header
      final sale = SalesCompanion.insert(
        id: saleId,
        createdAt: now,
        createdBy: kDevUser.id,
        deviceId: kDevUser.deviceId,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        changeAmount: changeAmount,
        synced: const Value(false),
      );
      await _db.into(_db.sales).insert(sale);

      for (final item in items) {
        final itemId = UuidUtil.generate();

        // 2. Insert sale item
        await _db.into(_db.saleItems).insert(
              SaleItemsCompanion.insert(
                id: itemId,
                saleId: saleId,
                productId: item.productId,
                quantity: item.quantity,
                sellingPrice: item.sellingPrice,
                subtotal: item.subtotal,
              ),
            );

        // 3. Decrement product stock
        await (_db.update(_db.products)
              ..where((p) => p.id.equals(item.productId)))
            .write(
          ProductsCompanion(
            currentStock: Value(item.currentStock - item.quantity),
            updatedAt: Value(now),
            updatedBy: Value(kDevUser.id),
            synced: const Value(false),
          ),
        );

        // 4. Insert stock movement (append-only)
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: UuidUtil.generate(),
                productId: item.productId,
                quantityChange: -item.quantity, // negative = stock out
                sourceType: 'sale',
                sourceId: saleId,
                createdAt: now,
                createdBy: kDevUser.id,
                deviceId: kDevUser.deviceId,
                synced: const Value(false),
              ),
            );
      }

      // Return the inserted sale record
      return (_db.select(_db.sales)..where((s) => s.id.equals(saleId)))
          .getSingle();
    });
  }
}
