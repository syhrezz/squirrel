/// Represents the operation type for a sync queue entry.
enum SyncOperation {
  create,
  update,
  delete;

  String get value => name;

  static SyncOperation fromValue(String value) {
    return SyncOperation.values.firstWhere((e) => e.value == value);
  }
}

/// Represents the status of a sync queue entry.
enum SyncStatus {
  pending,
  syncing,
  failed;

  String get value => name;

  static SyncStatus fromValue(String value) {
    return SyncStatus.values.firstWhere((e) => e.value == value);
  }
}

/// Represents the outcome of a sync session.
enum SyncSessionStatus {
  success,
  partial,
  failed;

  String get value => name;
}

/// Identifies which tables use which conflict strategy.
///
/// This is the registry used by the sync engine to decide how to handle
/// conflicts when the same record exists on multiple devices.
enum SyncTableConfig {
  /// Products and Customers: last-write-wins (mutable, last updated_at wins)
  products('products', isAppendOnly: false),
  customers('customers', isAppendOnly: false),

  /// All other tables: append-only (never update or delete on server)
  sales('sales', isAppendOnly: true),
  saleItems('sale_items', isAppendOnly: true),
  restocks('restocks', isAppendOnly: true),
  restockItems('restock_items', isAppendOnly: true),
  debtTransactions('debt_transactions', isAppendOnly: true),
  stockMovements('stock_movements', isAppendOnly: true);

  const SyncTableConfig(this.tableName, {required this.isAppendOnly});

  final String tableName;
  final bool isAppendOnly;

  static SyncTableConfig? forTable(String tableName) {
    try {
      return SyncTableConfig.values
          .firstWhere((c) => c.tableName == tableName);
    } catch (_) {
      return null;
    }
  }
}

/// Snapshot of the current sync queue state, used by UI and dev tools.
class SyncQueueSnapshot {
  const SyncQueueSnapshot({
    required this.pending,
    required this.syncing,
    required this.failed,
    required this.total,
  });

  final int pending;
  final int syncing;
  final int failed;
  final int total;

  bool get isEmpty => total == 0;
  bool get hasFailures => failed > 0;
}

/// Result returned after a sync session completes.
class SyncResult {
  const SyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.failed,
    required this.durationMs,
    required this.status,
    this.errorMessage,
  });

  const SyncResult.noOp()
      : uploaded = 0,
        downloaded = 0,
        failed = 0,
        durationMs = 0,
        status = SyncSessionStatus.success,
        errorMessage = null;

  final int uploaded;
  final int downloaded;
  final int failed;
  final int durationMs;
  final SyncSessionStatus status;
  final String? errorMessage;
}
