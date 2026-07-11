import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/uuid_util.dart';
import '../../models/retry_policy.dart';
import '../../models/sync_cursor.dart';
import '../../models/sync_models.dart';

/// Abstract interface for sync queue and device info operations.
///
/// Business features never depend on this interface.
/// Only [SyncService] and [SyncManager] use it.
abstract class SyncRepository {
  // --- Queue operations ---

  /// Adds a new entry to the sync queue for a business record.
  /// Called inside business SQLite transactions so if the business
  /// transaction rolls back, the queue entry is also rolled back.
  Future<void> enqueueCreate({
    required String tableName,
    required String recordId,
  });

  Future<void> enqueueUpdate({
    required String tableName,
    required String recordId,
  });

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
  });

  /// Returns all pending entries ready to be synced.
  /// Skips entries where nextRetryAt > now (exponential backoff).
  Future<List<SyncQueueEntry>> getPending();

  /// Returns all failed entries (for dev tools display).
  Future<List<SyncQueueEntry>> getFailed();

  /// Returns the current queue snapshot for UI display.
  Future<SyncQueueSnapshot> getQueueSnapshot();

  /// Marks a queue entry as successfully synced and removes it.
  Future<void> markSuccess(String queueId);

  /// Marks a queue entry as failed and schedules retry.
  Future<void> markFailure({
    required String queueId,
    required String error,
    required RetryPolicy retryPolicy,
  });

  /// Marks all pending entries as 'syncing' before uploading.
  Future<void> markBatchSyncing(List<String> queueIds);

  /// Resets all 'syncing' entries back to 'pending'.
  /// Called if the sync session is interrupted.
  Future<void> resetSyncingToPending();

  /// Removes all successfully completed entries older than [before].
  Future<void> clearCompleted({required int before});

  // --- Sync log ---

  Future<String> startSyncLog();
  Future<void> finishSyncLog({
    required String logId,
    required SyncResult result,
  });
  Future<List<SyncLogEntry>> getRecentLogs({int limit = 10});

  // --- Device info ---

  Future<DeviceInfoEntry?> getDeviceInfo();
  Future<void> upsertDeviceInfo(DeviceInfoEntry info);
  Future<void> updateLastSyncAt(int timestamp);
  Future<void> updatePullCursor(SyncCursor cursor);
  Future<SyncCursor> getPullCursor();
}

/// Drift (SQLite) implementation of [SyncRepository].
class DriftSyncRepository implements SyncRepository {
  const DriftSyncRepository(this._db);
  final AppDatabase _db;

  // -------------------------------------------------------------------------
  // Queue operations
  // -------------------------------------------------------------------------

  @override
  Future<void> enqueueCreate({
    required String tableName,
    required String recordId,
  }) => _enqueue(tableName, recordId, 'create');

  @override
  Future<void> enqueueUpdate({
    required String tableName,
    required String recordId,
  }) => _enqueue(tableName, recordId, 'update');

  @override
  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
  }) => _enqueue(tableName, recordId, 'delete');

  Future<void> _enqueue(
    String tableName,
    String recordId,
    String operation,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: UuidUtil.generate(),
            targetTable: tableName,
            recordId: recordId,
            operation: operation,
            status: const Value('pending'),
            retryCount: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.select(_db.syncQueue)
          ..where((q) =>
              q.status.equals('pending') |
              (q.status.equals('failed') &
                  (q.nextRetryAt.isNull() |
                      q.nextRetryAt.isSmallerOrEqualValue(now))))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  @override
  Future<List<SyncQueueEntry>> getFailed() async {
    return (_db.select(_db.syncQueue)
          ..where((q) => q.status.equals('failed'))
          ..orderBy([(q) => OrderingTerm.desc(q.updatedAt)]))
        .get();
  }

  @override
  Future<SyncQueueSnapshot> getQueueSnapshot() async {
    final all = await _db.select(_db.syncQueue).get();
    final pending = all.where((q) => q.status == 'pending').length;
    final syncing = all.where((q) => q.status == 'syncing').length;
    final failed = all.where((q) => q.status == 'failed').length;
    return SyncQueueSnapshot(
      pending: pending,
      syncing: syncing,
      failed: failed,
      total: all.length,
    );
  }

  @override
  Future<void> markSuccess(String queueId) async {
    await (_db.delete(_db.syncQueue)
          ..where((q) => q.id.equals(queueId)))
        .go();
  }

  @override
  Future<void> markFailure({
    required String queueId,
    required String error,
    required RetryPolicy retryPolicy,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = await (_db.select(_db.syncQueue)
          ..where((q) => q.id.equals(queueId)))
        .getSingleOrNull();
    if (entry == null) return;

    final newRetryCount = entry.retryCount + 1;
    final nextRetry = retryPolicy.nextRetryAt(newRetryCount);

    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(queueId)))
        .write(
      SyncQueueCompanion(
        status: const Value('failed'),
        retryCount: Value(newRetryCount),
        lastError: Value(error),
        updatedAt: Value(now),
        nextRetryAt: Value(nextRetry),
      ),
    );
  }

  @override
  Future<void> markBatchSyncing(List<String> queueIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in queueIds) {
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(id)))
          .write(
        SyncQueueCompanion(
          status: const Value('syncing'),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> resetSyncingToPending() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.syncQueue)
          ..where((q) => q.status.equals('syncing')))
        .write(
      SyncQueueCompanion(
        status: const Value('pending'),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> clearCompleted({required int before}) async {
    await (_db.delete(_db.syncQueue)
          ..where((q) =>
              q.status.equals('failed') &
              q.updatedAt.isSmallerOrEqualValue(before)))
        .go();
  }

  // -------------------------------------------------------------------------
  // Sync log
  // -------------------------------------------------------------------------

  @override
  Future<String> startSyncLog() async {
    final id = UuidUtil.generate();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.syncLog).insert(SyncLogCompanion.insert(
      id: id,
      startedAt: now,
      status: 'running',
    ));
    return id;
  }

  @override
  Future<void> finishSyncLog({
    required String logId,
    required SyncResult result,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.syncLog)..where((l) => l.id.equals(logId))).write(
      SyncLogCompanion(
        finishedAt: Value(now),
        uploadedRecords: Value(result.uploaded),
        downloadedRecords: Value(result.downloaded),
        failedRecords: Value(result.failed),
        durationMs: Value(result.durationMs),
        status: Value(result.status.value),
        errorMessage: Value(result.errorMessage),
      ),
    );
  }

  @override
  Future<List<SyncLogEntry>> getRecentLogs({int limit = 10}) async {
    return (_db.select(_db.syncLog)
          ..orderBy([(l) => OrderingTerm.desc(l.startedAt)])
          ..limit(limit))
        .get();
  }

  // -------------------------------------------------------------------------
  // Device info
  // -------------------------------------------------------------------------

  @override
  Future<DeviceInfoEntry?> getDeviceInfo() async {
    return _db.select(_db.deviceInfo).getSingleOrNull();
  }

  @override
  Future<void> upsertDeviceInfo(DeviceInfoEntry info) async {
    await _db.into(_db.deviceInfo).insertOnConflictUpdate(
          DeviceInfoCompanion.insert(
            deviceId: info.deviceId,
            deviceName: info.deviceName,
            platform: info.platform,
            appVersion: info.appVersion,
            createdAt: info.createdAt,
          ),
        );
  }

  @override
  Future<void> updateLastSyncAt(int timestamp) async {
    final info = await getDeviceInfo();
    if (info == null) return;
    await (_db.update(_db.deviceInfo)
          ..where((d) => d.deviceId.equals(info.deviceId)))
        .write(DeviceInfoCompanion(lastSyncAt: Value(timestamp)));
  }

  @override
  Future<void> updatePullCursor(SyncCursor cursor) async {
    final info = await getDeviceInfo();
    if (info == null) return;
    await (_db.update(_db.deviceInfo)
          ..where((d) => d.deviceId.equals(info.deviceId)))
        .write(DeviceInfoCompanion(
            lastPullTimestamp: Value(cursor.lastPullTimestamp)));
  }

  @override
  Future<SyncCursor> getPullCursor() async {
    final info = await getDeviceInfo();
    return SyncCursor(lastPullTimestamp: info?.lastPullTimestamp);
  }
}

// Type aliases for readability — these are the Drift-generated row types
typedef SyncQueueEntry = SyncQueueData;
typedef SyncLogEntry = SyncLogData;
typedef DeviceInfoEntry = DeviceInfoData;
