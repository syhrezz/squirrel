/// Idempotency service interface.
///
/// Prevents the sync engine from processing the same remote record twice.
/// When the server sends a record, we check if we already applied it.
/// If yes, we skip it. If no, we apply it and mark it as processed.
///
/// This is critical for safe retry logic:
/// If a pull partially succeeds and then fails, we can retry the entire
/// pull safely because already-applied records will be skipped.
///
/// The concrete implementation (Phase 7) will use a local SQLite table
/// to track processed record IDs.
abstract class IdempotencyService {
  /// Returns true if [recordId] from [tableName] has already been applied.
  Future<bool> isAlreadyProcessed({
    required String tableName,
    required String recordId,
  });

  /// Marks [recordId] from [tableName] as successfully applied.
  /// Should be called after a record is written to the local database.
  Future<void> markProcessed({
    required String tableName,
    required String recordId,
  });

  /// Clears all processed records older than [before] (epoch ms).
  /// Used to prevent the idempotency table from growing indefinitely.
  Future<void> clearOlderThan(int before);
}

/// No-op implementation used until Phase 7.
/// Always returns false (not processed) and does nothing on mark.
/// Safe to use in all phases — it simply means no deduplication yet.
class NoOpIdempotencyService implements IdempotencyService {
  const NoOpIdempotencyService();

  @override
  Future<bool> isAlreadyProcessed({
    required String tableName,
    required String recordId,
  }) async => false;

  @override
  Future<void> markProcessed({
    required String tableName,
    required String recordId,
  }) async {}

  @override
  Future<void> clearOlderThan(int before) async {}
}
