import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote_sync_data_source.dart';
import '../../models/sync_cursor.dart';
import 'supabase_config.dart';

/// Concrete Supabase implementation of [RemoteSyncDataSource].
///
/// This is the ONLY file that imports supabase_flutter.
/// All other sync infrastructure depends only on the interface.
///
/// Behaviour when not configured:
/// If [SupabaseConfig.isConfigured] returns false, all methods
/// fall back to no-op behaviour identical to [NoOpRemoteSyncDataSource].
/// This prevents crashes during development when Supabase credentials
/// have not yet been configured.
///
/// Phase 8 will wire this class into [sync_providers.dart] by replacing
/// [NoOpRemoteSyncDataSource] with this implementation.
class SupabaseRemoteSyncDataSource implements RemoteSyncDataSource {
  SupabaseRemoteSyncDataSource({required this.config});

  final SupabaseConfig config;

  SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // isReachable
  // ---------------------------------------------------------------------------

  @override
  Future<bool> isReachable() async {
    if (!config.isConfigured) return false;
    try {
      // Lightweight health check — query device_info with limit 0.
      await _client
          .from('device_info')
          .select('device_id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // pushRecords
  // ---------------------------------------------------------------------------

  /// Pushes a batch of records to Supabase using upsert.
  ///
  /// Records are grouped by table and sent as bulk upserts.
  /// Append-only tables use INSERT (ignore conflicts) to prevent
  /// accidental updates to historical records.
  /// Mutable tables (products, customers) use UPSERT (update on conflict).
  ///
  /// Returns the number of records successfully uploaded.
  @override
  Future<int> pushRecords(List<SyncPayload> records) async {
    if (!config.isConfigured) return 0;
    if (records.isEmpty) return 0;

    int uploaded = 0;

    // Group records by table name for efficient bulk operations
    final grouped = <String, List<SyncPayload>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.tableName, () => []).add(record);
    }

    for (final entry in grouped.entries) {
      final tableName = entry.key;
      final tableRecords = entry.value;
      final isAppendOnly = _isAppendOnly(tableName);

      try {
        // Convert each record's data map and inject organization_id
        final rows = tableRecords
            .map((r) => {
                  ...r.data,
                  'organization_id': config.organizationId,
                })
            .toList();

        if (isAppendOnly) {
          // Append-only: INSERT, ignore if already exists
          await _client
              .from(tableName)
              .insert(rows)
              .timeout(const Duration(seconds: 30));
        } else {
          // Mutable: UPSERT (update on conflict by primary key)
          await _client
              .from(tableName)
              .upsert(rows)
              .timeout(const Duration(seconds: 30));
        }

        uploaded += rows.length;
      } catch (e) {
        // Log and continue — failed records will be retried via queue
        // ignore: avoid_print
        print('[SupabaseSync] pushRecords error for $tableName: $e');
      }
    }

    return uploaded;
  }

  // ---------------------------------------------------------------------------
  // pullRecords
  // ---------------------------------------------------------------------------

  /// Pulls all records changed since the cursor timestamp.
  ///
  /// Uses the [pull_changes_since] PostgreSQL function (migration 007)
  /// which returns a unified result set across all sync tables ordered
  /// by updated_at asc. This advances the cursor safely — if the pull
  /// is interrupted, the next pull will re-request the same window.
  @override
  Future<PullResult> pullRecords(SyncCursor cursor) async {
    if (!config.isConfigured) {
      return PullResult(records: const [], newCursor: cursor);
    }

    try {
      // Convert epoch ms cursor to ISO 8601 string for Postgres timestamptz
      final sinceTs = cursor.lastPullTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(cursor.lastPullTimestamp!,
                  isUtc: true)
              .toIso8601String()
          : '1970-01-01T00:00:00Z';

      final response = await _client
          .rpc('pull_changes_since', params: {
            'p_organization_id': config.organizationId,
            'p_since': sinceTs,
          })
          .timeout(const Duration(seconds: 60));

      final rows = (response as List).cast<Map<String, dynamic>>();

      if (rows.isEmpty) {
        return PullResult(records: const [], newCursor: cursor);
      }

      // Parse remote records
      final remoteRecords = rows.map((row) {
        // updated_at from Postgres is an ISO 8601 string
        final updatedAtStr = row['updated_at'] as String?;
        final updatedAtMs = updatedAtStr != null
            ? DateTime.parse(updatedAtStr).millisecondsSinceEpoch
            : 0;

        return RemoteRecord(
          tableName: row['table_name'] as String,
          recordId: row['record_id'] as String,
          operation: row['operation'] as String,
          data: (row['data'] as Map<String, dynamic>?) ?? {},
          updatedAt: updatedAtMs,
        );
      }).toList();

      // Advance cursor to the latest updated_at in this batch
      final latestMs = remoteRecords
          .map((r) => r.updatedAt)
          .fold<int>(cursor.lastPullTimestamp ?? 0, (a, b) => a > b ? a : b);

      return PullResult(
        records: remoteRecords,
        newCursor: cursor.advance(latestMs),
      );
    } catch (e) {
      // Return empty pull with unchanged cursor — will retry on next session
      // ignore: avoid_print
      print('[SupabaseSync] pullRecords error: $e');
      return PullResult(records: const [], newCursor: cursor);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true if the given table is append-only.
  /// Append-only tables use INSERT (not UPSERT) to prevent history mutation.
  static bool _isAppendOnly(String tableName) {
    const appendOnlyTables = {
      'sales',
      'sale_items',
      'restocks',
      'restock_items',
      'debt_transactions',
      'stock_movements',
    };
    return appendOnlyTables.contains(tableName);
  }
}
