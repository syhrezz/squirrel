import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../../../core/utils/dev_user.dart';
import '../../../../features/sync/data/repositories/sync_repository.dart';

/// CRUD operations for [Customer] records.
///
/// Conflict strategy: last-write-wins (by updated_at) on sync.
abstract class CustomerRepository {
  Stream<List<Customer>> watchAllActive();
  Stream<Customer?> watchById(String id);
  Future<Customer?> getById(String id);
  Future<Customer> create(CustomersCompanion data);
  Future<Customer> update(String id, CustomersCompanion data);

  /// Soft delete — deactivates customer but preserves all debt history.
  Future<void> deactivate(String id);
}

class DriftCustomerRepository implements CustomerRepository {
  const DriftCustomerRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncRepository _sync;

  @override
  Stream<List<Customer>> watchAllActive() {
    return (_db.select(_db.customers)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  @override
  Stream<Customer?> watchById(String id) {
    return (_db.select(_db.customers)
          ..where((c) => c.id.equals(id)))
        .watchSingleOrNull();
  }

  @override
  Future<Customer?> getById(String id) {
    return (_db.select(_db.customers)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<Customer> create(CustomersCompanion data) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = UuidUtil.generate();
    final companion = data.copyWith(
      id: Value(id),
      createdAt: Value(now),
      updatedAt: Value(now),
      createdBy: Value(kDevUser.id),
      updatedBy: Value(kDevUser.id),
      synced: const Value(false),
    );
    await _db.into(_db.customers).insert(companion);
    await _sync.enqueueCreate(tableName: 'customers', recordId: id);
    return (await getById(id))!;
  }

  @override
  Future<Customer> update(String id, CustomersCompanion data) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = data.copyWith(
      id: Value(id),
      updatedAt: Value(now),
      updatedBy: Value(kDevUser.id),
      synced: const Value(false),
    );
    await (_db.update(_db.customers)..where((c) => c.id.equals(id)))
        .write(companion);
    await _sync.enqueueUpdate(tableName: 'customers', recordId: id);
    return (await getById(id))!;
  }

  @override
  Future<void> deactivate(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        updatedBy: Value(kDevUser.id),
        synced: const Value(false),
      ),
    );
    await _sync.enqueueUpdate(tableName: 'customers', recordId: id);
  }
}
