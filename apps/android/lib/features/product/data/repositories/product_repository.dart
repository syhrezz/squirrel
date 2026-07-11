import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';

/// Abstract interface for product data operations.
///
/// Keeps feature code decoupled from the Drift implementation.
/// A future remote implementation can be swapped in without
/// touching any screen or provider code.
abstract class ProductRepository {
  /// Watch all active products, ordered by name.
  Stream<List<Product>> watchAll();

  /// Watch a single product by id.
  Stream<Product?> watchById(String id);

  /// Get a single product by id (one-time read).
  Future<Product?> getById(String id);

  /// Insert a new product. Returns the created product.
  Future<Product> create(ProductsCompanion data);

  /// Update an existing product (last-write-wins).
  Future<Product> update(String id, ProductsCompanion data);

  /// Soft-delete a product by marking it inactive.
  Future<void> deactivate(String id);
}

/// Drift (SQLite) implementation of [ProductRepository].
class DriftProductRepository implements ProductRepository {
  const DriftProductRepository(this._db);

  final AppDatabase _db;

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
  }
}
