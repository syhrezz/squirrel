import '../models/retry_policy.dart';
import '../models/sync_models.dart';
import '../data/repositories/sync_repository.dart';
import 'remote_sync_data_source.dart';
import 'conflict_strategy.dart';
import 'idempotency_service.dart';

/// Abstract interface for the sync service.
///
/// Business features never depend on this.
/// [SyncManager] calls this interface.
abstract class SyncService {
  /// Runs a full sync cycle: push local changes, pull remote changes.
  /// Returns the result of the session.
  Future<SyncResult> sync();

  /// Returns true if a sync session is currently running.
  bool get isRunning;
}

/// No-op sync service — used until Phase 7 (Supabase).
///
/// All operations succeed immediately with zero records transferred.
/// The queue is inspected but not drained (no remote to send to).
class NoOpSyncService implements SyncService {
  const NoOpSyncService();

  @override
  bool get isRunning => false;

  @override
  Future<SyncResult> sync() async => const SyncResult.noOp();
}

/// Full sync service implementation.
///
/// Used in Phase 7 when Supabase is connected.
/// Depends on interfaces only — easily testable.
class DefaultSyncService implements SyncService {
  DefaultSyncService({
    required this._repository,
    required this._remote,
    required this._idempotency,
  });

  final SyncRepository _repository;
  final RemoteSyncDataSource _remote;
  final IdempotencyService _idempotency;
  final RetryPolicy _retryPolicy = RetryPolicy();

  bool _isRunning = false;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<SyncResult> sync() async {
    if (_isRunning) return const SyncResult.noOp();

    final logId = await _repository.startSyncLog();
    final start = DateTime.now().millisecondsSinceEpoch;
    _isRunning = true;

    int uploaded = 0;
    int downloaded = 0;
    int failed = 0;
    String? errorMessage;
    SyncSessionStatus status = SyncSessionStatus.success;

    try {
      // --- PUSH: Upload local pending records ---
      final pending = await _repository.getPending();
      if (pending.isNotEmpty) {
        final ids = pending.map((e) => e.id).toList();
        await _repository.markBatchSyncing(ids);

        final payloads = pending
            .map((e) => SyncPayload(
                  tableName: e.targetTable,
                  recordId: e.recordId,
                  operation: e.operation,
                  data: const {}, // Phase 7: populate from business tables
                  deviceId: e.targetTable, // placeholder
                  createdAt: e.createdAt,
                ))
            .toList();

        try {
          final count = await _remote.pushRecords(payloads);
          uploaded = count;
          for (final id in ids) {
            await _repository.markSuccess(id);
          }
        } catch (e) {
          failed = ids.length;
          for (int i = 0; i < ids.length; i++) {
            await _repository.markFailure(
              queueId: ids[i],
              error: e.toString(),
              retryPolicy: _retryPolicy,
            );
          }
        }
      }

      // --- PULL: Download remote changes ---
      try {
        final cursor = await _repository.getPullCursor();
        final pullResult = await _remote.pullRecords(cursor);

        for (final record in pullResult.records) {
          // Check idempotency
          final alreadyApplied = await _idempotency.isAlreadyProcessed(
            tableName: record.tableName,
            recordId: record.recordId,
          );
          if (alreadyApplied) continue;

          // Check conflict strategy
          final strategy =
              ConflictStrategyRegistry.forTable(record.tableName);
          final shouldAccept = strategy.shouldAcceptRemote(
            localUpdatedAt: null, // Phase 7: look up actual local record
            remoteUpdatedAt: record.updatedAt,
          );

          if (shouldAccept) {
            // Phase 7: apply record to local business table
            await _idempotency.markProcessed(
              tableName: record.tableName,
              recordId: record.recordId,
            );
            downloaded++;
          }
        }

        // Advance cursor
        await _repository.updatePullCursor(pullResult.newCursor);
      } catch (e) {
        errorMessage = e.toString();
        status = failed > 0 ? SyncSessionStatus.failed : SyncSessionStatus.partial;
      }

      if (failed > 0 && status == SyncSessionStatus.success) {
        status = SyncSessionStatus.partial;
      }

      await _repository.updateLastSyncAt(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      errorMessage = e.toString();
      status = SyncSessionStatus.failed;
      await _repository.resetSyncingToPending();
    } finally {
      _isRunning = false;
    }

    final durationMs = DateTime.now().millisecondsSinceEpoch - start;
    final result = SyncResult(
      uploaded: uploaded,
      downloaded: downloaded,
      failed: failed,
      durationMs: durationMs,
      status: status,
      errorMessage: errorMessage,
    );

    await _repository.finishSyncLog(logId: logId, result: result);
    return result;
  }
}
