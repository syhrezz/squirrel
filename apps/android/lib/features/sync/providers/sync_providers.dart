import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/sync_repository.dart';
import '../models/sync_models.dart';
import '../services/conflict_strategy.dart';
import '../services/idempotency_service.dart';
import '../services/remote_sync_data_source.dart';
import '../services/sync_manager.dart';
import '../services/sync_service.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return DriftSyncRepository(ref.watch(appDatabaseProvider));
});

// ---------------------------------------------------------------------------
// Service dependencies — all use no-op implementations until Phase 7
// ---------------------------------------------------------------------------

final remoteSyncDataSourceProvider =
    Provider<RemoteSyncDataSource>((ref) {
  return const NoOpRemoteSyncDataSource();
});

final idempotencyServiceProvider =
    Provider<IdempotencyService>((ref) {
  return const NoOpIdempotencyService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return DefaultSyncService(
    repository: ref.watch(syncRepositoryProvider),
    remote: ref.watch(remoteSyncDataSourceProvider),
    idempotency: ref.watch(idempotencyServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// SyncManager — single instance, started by the app
// ---------------------------------------------------------------------------

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    syncService: ref.watch(syncServiceProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

// ---------------------------------------------------------------------------
// Observables for UI / dev tools
// ---------------------------------------------------------------------------

/// Current sync queue snapshot — refreshed on demand.
final syncQueueSnapshotProvider = FutureProvider<SyncQueueSnapshot>((ref) {
  return ref.watch(syncRepositoryProvider).getQueueSnapshot();
});

/// Last 10 sync log entries.
final recentSyncLogsProvider =
    FutureProvider<List<SyncLogEntry>>((ref) {
  return ref.watch(syncRepositoryProvider).getRecentLogs(limit: 10);
});

/// Pending queue entries (for dev tools).
final pendingSyncQueueProvider =
    FutureProvider<List<SyncQueueEntry>>((ref) {
  return ref.watch(syncRepositoryProvider).getPending();
});

/// Failed queue entries (for dev tools).
final failedSyncQueueProvider =
    FutureProvider<List<SyncQueueEntry>>((ref) {
  return ref.watch(syncRepositoryProvider).getFailed();
});

/// Device info row.
final deviceInfoProvider = FutureProvider<DeviceInfoEntry?>((ref) {
  return ref.watch(syncRepositoryProvider).getDeviceInfo();
});

/// Conflict strategy registry — used for documentation in dev tools.
final conflictStrategyRegistryProvider =
    Provider<ConflictStrategyRegistry>((_) => ConflictStrategyRegistry());

extension ConflictStrategyRegistryAccess on ConflictStrategyRegistry {
  // Expose the registry for dev tools display
  Map<String, String> get tableStrategies => {
        'products': 'LastWriteWins',
        'customers': 'LastWriteWins',
        'sales': 'AppendOnly',
        'sale_items': 'AppendOnly',
        'restocks': 'AppendOnly',
        'restock_items': 'AppendOnly',
        'debt_transactions': 'AppendOnly',
        'stock_movements': 'AppendOnly',
      };
}
