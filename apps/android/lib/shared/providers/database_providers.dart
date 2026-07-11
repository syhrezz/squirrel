import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../features/product/data/repositories/product_repository.dart';
import '../../features/sync/data/repositories/sync_repository.dart';

/// Provides the single [AppDatabase] instance for the whole app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides the shared [SyncRepository] backed by Drift.
final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return DriftSyncRepository(ref.watch(appDatabaseProvider));
});

/// Provides the [ProductRepository] backed by Drift.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return DriftProductRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  );
});
