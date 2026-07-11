import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../../shared/providers/database_providers.dart';
import '../data/repositories/sync_repository.dart';
import '../models/sync_models.dart';
import '../services/conflict_strategy.dart';
import '../services/idempotency_service.dart';
import '../services/record_serializer.dart';
import '../services/remote_sync_data_source.dart';
import '../services/supabase/supabase_config.dart';
import '../services/supabase/supabase_remote_sync_data_source.dart';
import '../services/sync_manager.dart';
import '../services/sync_service.dart';

// ---------------------------------------------------------------------------
// Supabase configuration — derived from AppEnv
// ---------------------------------------------------------------------------

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  return SupabaseConfig(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
    organizationId: AppEnv.organizationId,
  );
});

// ---------------------------------------------------------------------------
// Remote data source — real Supabase when configured, NoOp fallback otherwise
// ---------------------------------------------------------------------------

final remoteSyncDataSourceProvider =
    Provider<RemoteSyncDataSource>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (config.isConfigured) {
    return SupabaseRemoteSyncDataSource(config: config);
  }
  return const NoOpRemoteSyncDataSource();
});

final idempotencyServiceProvider =
    Provider<IdempotencyService>((ref) => const NoOpIdempotencyService());

final recordSerializerProvider = Provider<RecordSerializer>((ref) {
  return RecordSerializer(ref.watch(appDatabaseProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return DefaultSyncService(
    repository: ref.watch(syncRepositoryProvider),
    remote: ref.watch(remoteSyncDataSourceProvider),
    idempotency: ref.watch(idempotencyServiceProvider),
    serializer: ref.watch(recordSerializerProvider),
  );
});

// ---------------------------------------------------------------------------
// SyncManager — single instance, started by the app
// ---------------------------------------------------------------------------

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(syncService: ref.watch(syncServiceProvider));
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

/// Last sync timestamp from device_info (epoch ms). Null = never synced.
final lastSyncTimeProvider = FutureProvider<int?>((ref) async {
  final info = await ref.watch(deviceInfoProvider.future);
  return info?.lastSyncAt;
});

/// Whether Supabase is currently reachable.
/// Evaluated lazily — only checks when watched.
final supabaseConnectionProvider = FutureProvider<bool>((ref) {
  return ref.watch(remoteSyncDataSourceProvider).isReachable();
});

/// Whether the sync manager is currently running a sync session.
/// Polled from the SyncManager — not a stream, must be refreshed manually.
final syncIsRunningProvider = Provider<bool>((ref) {
  return ref.watch(syncManagerProvider).isSyncing;
});

/// The result of the most recently completed sync session.
/// Null if no sync has run since app start.
final lastSyncResultProvider = Provider<SyncResult?>((ref) {
  return ref.watch(syncManagerProvider).lastResult;
});

/// Organization ID from AppEnv — for display in dev tools and settings.
final organizationIdProvider = Provider<String>((_) => AppEnv.organizationId);

/// Conflict strategy registry — used for documentation in dev tools.
final conflictStrategyRegistryProvider =
    Provider<ConflictStrategyRegistry>((_) => ConflictStrategyRegistry());

extension ConflictStrategyRegistryAccess on ConflictStrategyRegistry {
  Map<String, String> get tableStrategies => {
        'products': 'LastWriteWins',
        'product_selling_options': 'LastWriteWins',
        'customers': 'LastWriteWins',
        'sales': 'AppendOnly',
        'sale_items': 'AppendOnly',
        'restocks': 'AppendOnly',
        'restock_items': 'AppendOnly',
        'debt_transactions': 'AppendOnly',
        'stock_movements': 'AppendOnly',
      };
}
