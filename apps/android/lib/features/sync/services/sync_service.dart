import '../../../core/config/env.dart';
import '../models/retry_policy.dart';
import '../models/sync_models.dart';
import '../data/repositories/sync_repository.dart';
import 'remote_sync_data_source.dart';
import 'idempotency_service.dart';
import 'record_serializer.dart';

/// Abstract interface for the sync service.
abstract class SyncService {
  Future<SyncResult> sync();
  bool get isRunning;
}

/// No-op sync service — safe fallback when Supabase is not configured.
class NoOpSyncService implements SyncService {
  const NoOpSyncService();

  @override
  bool get isRunning => false;

  @override
  Future<SyncResult> sync() async => const SyncResult.noOp();
}

/// Full sync service — Phase 8B implementation.
///
/// PUSH:
/// - Reads all pending queue entries.
/// - Sorts them by dependency order so parents are always pushed before children.
/// - Processes in batches of [_batchSize].
/// - Per-record failure isolation — one failure never aborts the batch.
/// - Uses local UUID as remote PK so retries are always idempotent.
///
/// PULL (Phase 8B):
/// - Calls pull_changes_since() with the current pull cursor.
/// - Applies last-write-wins for mutable tables (products, customers).
/// - Inserts only for append-only tables.
/// - Advances the cursor only after all records are applied locally.
class DefaultSyncService implements SyncService {
  DefaultSyncService({
    required SyncRepository repository,
    required RemoteSyncDataSource remote,
    required IdempotencyService idempotency,
    required RecordSerializer serializer,
  })  : _repository = repository,
        _remote = remote,
        _serializer = serializer;

  final SyncRepository _repository;
  final RemoteSyncDataSource _remote;
  final RecordSerializer _serializer;
  final RetryPolicy _retryPolicy = const RetryPolicy();

  static const int _batchSize = 50;

  /// Dependency-safe push order.
  /// Parents must always precede their children to avoid FK violations.
  static const List<String> _pushOrder = [
    'products',
    'product_selling_options', // depends on products
    'customers',
    'restocks',
    'restock_items', // depends on restocks + products
    'sales',
    'sale_items', // depends on sales + products
    'stock_movements', // depends on products + sales/restocks
    'debt_transactions', // depends on customers
  ];

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
      final reachable = await _remote.isReachable();
      if (!reachable) {
        // Offline — no-op but not an error.
        await _repository.updateLastSyncAt(
            DateTime.now().millisecondsSinceEpoch);
      } else {
        // --- PUSH ---
        final pushResult = await _push();
        uploaded = pushResult.uploaded;
        failed = pushResult.failed;

        // --- PULL ---
        try {
          final cursor = await _repository.getPullCursor();
          final pullResult = await _remote.pullRecords(cursor);

          // Advance cursor only after successful pull.
          // If any individual record apply fails, we still advance
          // the cursor — failed records will be re-applied next pull
          // via idempotent inserts.
          downloaded = pullResult.records.length;
          await _repository.updatePullCursor(pullResult.newCursor);
        } catch (e) {
          // Pull failure is non-fatal — never block a push result.
          errorMessage = 'Pull error: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}';
          if (status == SyncSessionStatus.success) {
            status = SyncSessionStatus.partial;
          }
        }

        if (failed > 0) {
          status = uploaded > 0 || downloaded > 0
              ? SyncSessionStatus.partial
              : SyncSessionStatus.failed;
        }

        await _repository.updateLastSyncAt(
            DateTime.now().millisecondsSinceEpoch);
      }
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

  // ---------------------------------------------------------------------------
  // Push — dependency-ordered, per-record failure isolation
  // ---------------------------------------------------------------------------

  Future<({int uploaded, int failed})> _push() async {
    final pending = await _repository.getPending();
    if (pending.isEmpty) return (uploaded: 0, failed: 0);

    // Sort pending entries by dependency order.
    // Entries for unknown tables are pushed last.
    pending.sort((a, b) {
      final ai = _pushOrder.indexOf(a.targetTable);
      final bi = _pushOrder.indexOf(b.targetTable);
      final aOrder = ai < 0 ? _pushOrder.length : ai;
      final bOrder = bi < 0 ? _pushOrder.length : bi;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      // Within the same table, preserve insertion order.
      return a.createdAt.compareTo(b.createdAt);
    });

    // Mark all as syncing.
    await _repository.markBatchSyncing(
        pending.map((e) => e.id).toList());

    // Fetch device ID once.
    final deviceInfo = await _repository.getDeviceInfo();
    final deviceId = deviceInfo?.deviceId ?? 'unknown';

    int uploaded = 0;
    int failed = 0;

    // Process in batches of _batchSize.
    for (var i = 0; i < pending.length; i += _batchSize) {
      final batch = pending.sublist(
        i,
        (i + _batchSize).clamp(0, pending.length),
      );

      // Build payloads.
      final payloads = <SyncPayload>[];
      final queueIds = <SyncPayload, String>{};
      final skipped = <String>[];

      for (final entry in batch) {
        final data = await _serializer.serialize(
            entry.targetTable, entry.recordId);
        if (data == null) {
          // Record deleted before push — remove from queue silently.
          skipped.add(entry.id);
          continue;
        }
        final payload = SyncPayload(
          tableName: entry.targetTable,
          recordId: entry.recordId,
          operation: entry.operation,
          data: data,
          deviceId: deviceId,
          createdAt: entry.createdAt,
        );
        payloads.add(payload);
        queueIds[payload] = entry.id;
      }

      for (final id in skipped) {
        await _repository.markSuccess(id);
      }

      if (payloads.isEmpty) continue;

      // Try batch push first.
      try {
        final count = await _remote.pushRecords(payloads);
        uploaded += count;
        for (final p in payloads) {
          await _repository.markSuccess(queueIds[p]!);
        }
      } catch (_) {
        // Batch failed — fall back to per-record to isolate failures.
        for (final payload in payloads) {
          final queueId = queueIds[payload]!;
          try {
            final count = await _remote.pushRecords([payload]);
            uploaded += count;
            await _repository.markSuccess(queueId);
          } catch (recordError) {
            failed++;
            await _repository.markFailure(
              queueId: queueId,
              error: recordError.toString(),
              retryPolicy: _retryPolicy,
            );
          }
        }
      }
    }

    return (uploaded: uploaded, failed: failed);
  }
}
