import '../models/sync_cursor.dart';

/// Remote sync data source interface.
///
/// This is the ONLY place in the codebase that will ever touch Supabase.
/// All sync infrastructure depends on this interface.
/// The concrete Supabase implementation will be added in Phase 7.
///
/// Business features never import this interface.
/// Only [SyncService] uses it.
abstract class RemoteSyncDataSource {
  /// Pushes a batch of local records to the server.
  ///
  /// [records] is a list of serialized record payloads.
  /// Returns the number of records successfully uploaded.
  Future<int> pushRecords(List<SyncPayload> records);

  /// Pulls records from the server that changed after [cursor].
  ///
  /// Returns a [PullResult] containing the records and the new cursor.
  Future<PullResult> pullRecords(SyncCursor cursor);

  /// Returns true if the remote is reachable.
  Future<bool> isReachable();
}

/// A serialized record ready to be sent to the remote.
class SyncPayload {
  const SyncPayload({
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.deviceId,
    required this.createdAt,
  });

  final String tableName;
  final String recordId;

  /// 'create' | 'update' | 'delete'
  final String operation;

  /// The record's fields as a key-value map.
  final Map<String, dynamic> data;

  final String deviceId;
  final int createdAt;
}

/// Result of a pull operation from the server.
class PullResult {
  const PullResult({
    required this.records,
    required this.newCursor,
  });

  final List<RemoteRecord> records;
  final SyncCursor newCursor;
}

/// A record received from the server during a pull.
class RemoteRecord {
  const RemoteRecord({
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.updatedAt,
  });

  final String tableName;
  final String recordId;
  final String operation;
  final Map<String, dynamic> data;
  final int updatedAt;
}

/// No-op remote data source — used until Phase 7.
/// All methods return success with zero records.
class NoOpRemoteSyncDataSource implements RemoteSyncDataSource {
  const NoOpRemoteSyncDataSource();

  @override
  Future<int> pushRecords(List<SyncPayload> records) async => 0;

  @override
  Future<PullResult> pullRecords(SyncCursor cursor) async {
    return PullResult(records: const [], newCursor: cursor);
  }

  @override
  Future<bool> isReachable() async => false;
}
