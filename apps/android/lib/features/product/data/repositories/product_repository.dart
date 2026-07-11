import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../../sync/data/repositories/sync_repository.dart';
import '../models/selling_option_model.dart';

/// Abstract interface for product data operations.
abstract class ProductRepository {
  Stream<List<Product>> watchAll();
  Stream<Product?> watchById(String id);
  Future<Product?> getById(String id);
  Future<Product> create(ProductsCompanion data);
  Future<Product> update(String id, ProductsCompanion data);
  Future<void> deactivate(String id);

  // Selling options
  Future<List<ProductSellingOption>> getSellingOptions(String productId);
  Stream<List<ProductSellingOption>> watchSellingOptions(String productId);
  Future<void> saveSellingOptions(
      String productId, List<SellingOptionInput> options);
}

/// Input model for creating/updating a selling option.
class SellingOptionInput {
  const SellingOptionInput({
    this.id,
    required this.displayName,
    required this.inventoryQuantity,
    required this.sellingPrice,
    required this.displayOrder,
  });

  /// Existing ID for updates, null for new options.
  final String? id;
  final String displayName;
  final int inventoryQuantity;
  final int sellingPrice;
  final int displayOrder;
}

/// Drift (SQLite) implementation of [ProductRepository].
class DriftProductRepository implements ProductRepository {
  const DriftProductRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncRepository _sync;

  @override
  Stream<List<Product>> watchAll() {
    return (_db.select(_db.products)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  @override
  Stream<Product?> watchById(String id) {
    return (_db.select(_db.products)
          ..where((p) => p.id.equals(id)))
        .watchSingleOrNull();
  }

  @override
  Future<Product?> getById(String id) {
    return (_db.select(_db.products)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<Product> create(ProductsCompanion data) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = UuidUtil.generate();

    final companion = data.copyWith(
      id: Value(id),
      createdAt: Value(now),
      updatedAt: Value(now),
      createdBy: Value(kDevUser.id),
      updatedBy: Value(kDevUser.id),
      deviceId: Value(kDevUser.deviceId),
      synced: const Value(false),
    );

    await _db.into(_db.products).insert(companion);
    await _sync.enqueueCreate(tableName: 'products', recordId: id);
    return (await getById(id))!;
  }

  @override
  Future<Product> update(String id, ProductsCompanion data) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = data.copyWith(
      id: Value(id),
      updatedAt: Value(now),
      updatedBy: Value(kDevUser.id),
      synced: const Value(false),
    );

    await (_db.update(_db.products)..where((p) => p.id.equals(id)))
        .write(companion);
    await _sync.enqueueUpdate(tableName: 'products', recordId: id);
    return (await getById(id))!;
  }

  @override
  Future<void> deactivate(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.products)..where((p) => p.id.equals(id))).write(
      ProductsCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        updatedBy: Value(kDevUser.id),
        synced: const Value(false),
      ),
    );
    await _sync.enqueueUpdate(tableName: 'products', recordId: id);
  }

  // ---------------------------------------------------------------------------
  // Selling options
  // ---------------------------------------------------------------------------

  @override
  Future<List<ProductSellingOption>> getSellingOptions(
      String productId) async {
    return (_db.select(_db.productSellingOptions)
          ..where((o) =>
              o.productId.equals(productId) & o.isActive.equals(true))
          ..orderBy([(o) => OrderingTerm.asc(o.displayOrder)]))
        .get();
  }

  @override
  Stream<List<ProductSellingOption>> watchSellingOptions(
      String productId) {
    return (_db.select(_db.productSellingOptions)
          ..where((o) =>
              o.productId.equals(productId) & o.isActive.equals(true))
          ..orderBy([(o) => OrderingTerm.asc(o.displayOrder)]))
        .watch();
  }

  /// Replaces all selling options for a product.
  ///
  /// Strategy: soft-delete existing options, insert new ones.
  /// This preserves history while ensuring the active list is fresh.
  @override
  Future<void> saveSellingOptions(
      String productId, List<SellingOptionInput> options) async {
    // Soft-delete all existing active options
    await (_db.update(_db.productSellingOptions)
          ..where((o) => o.productId.equals(productId)))
        .write(const ProductSellingOptionsCompanion(
      isActive: Value(false),
    ));

    // Insert new options
    for (final option in options) {
      final id = option.id ?? UuidUtil.generate();
      await _db.into(_db.productSellingOptions).insertOnConflictUpdate(
            ProductSellingOptionsCompanion.insert(
              id: id,
              productId: productId,
              displayName: option.displayName,
              quantity: option.inventoryQuantity,
              sellingPrice: option.sellingPrice,
              displayOrder: Value(option.displayOrder),
              isActive: const Value(true),
            ),
          );
      await _sync.enqueueCreate(
          tableName: 'product_selling_options', recordId: id);
    }
  }
}
