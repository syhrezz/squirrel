/// Conflict resolution strategy interface.
///
/// Each table in the sync system has one strategy assigned.
/// The strategy decides what happens when the same record exists
/// on the local device and on the server with different values.
abstract class ConflictStrategy {
  const ConflictStrategy();

  /// The name of this strategy for debugging and logging.
  String get name;

  /// Returns true if the remote version should overwrite the local version.
  ///
  /// [localUpdatedAt]  epoch ms of the local record's last update.
  /// [remoteUpdatedAt] epoch ms of the remote record's last update.
  bool shouldAcceptRemote({
    required int? localUpdatedAt,
    required int remoteUpdatedAt,
  });
}

/// Append-only conflict strategy.
///
/// Used for: Sales, SaleItems, Restocks, RestockItems,
///           DebtTransactions, StockMovements.
///
/// These tables never conflict. Each record is created once by one device
/// and never modified. If the record already exists locally, it is identical
/// to the remote — skip it. If it does not exist, insert it.
class AppendOnlyConflictStrategy extends ConflictStrategy {
  const AppendOnlyConflictStrategy();

  @override
  String get name => 'AppendOnly';

  @override
  bool shouldAcceptRemote({
    required int? localUpdatedAt,
    required int remoteUpdatedAt,
  }) {
    // If the record already exists locally, we already have it — skip.
    // If it does not exist locally (localUpdatedAt == null), accept it.
    return localUpdatedAt == null;
  }
}

/// Last-write-wins conflict strategy.
///
/// Used for: Products, Customers.
///
/// When the same record is updated on two devices while offline,
/// the version with the most recent [updatedAt] timestamp wins.
/// The older version is discarded.
///
/// This is safe for Products and Customers because:
/// - Products are edited rarely (price changes, stock corrections)
/// - Customers are edited rarely (name/phone corrections)
/// - The window for simultaneous edits is small in a family shop
class LastWriteWinsConflictStrategy extends ConflictStrategy {
  const LastWriteWinsConflictStrategy();

  @override
  String get name => 'LastWriteWins';

  @override
  bool shouldAcceptRemote({
    required int? localUpdatedAt,
    required int remoteUpdatedAt,
  }) {
    if (localUpdatedAt == null) return true; // record is new locally — accept
    return remoteUpdatedAt > localUpdatedAt;  // remote is newer — accept
  }
}

/// Registry that maps each table name to its conflict strategy.
///
/// The sync engine calls [forTable] to determine how to handle
/// a received record from the server.
class ConflictStrategyRegistry {
  const ConflictStrategyRegistry();

  static const _appendOnly = AppendOnlyConflictStrategy();
  static const _lastWriteWins = LastWriteWinsConflictStrategy();

  static const Map<String, ConflictStrategy> _registry = {
    'products': _lastWriteWins,
    'customers': _lastWriteWins,
    'sales': _appendOnly,
    'sale_items': _appendOnly,
    'restocks': _appendOnly,
    'restock_items': _appendOnly,
    'debt_transactions': _appendOnly,
    'stock_movements': _appendOnly,
  };

  /// Returns the conflict strategy for the given table name.
  /// Returns [AppendOnlyConflictStrategy] as a safe default for unknown tables.
  static ConflictStrategy forTable(String tableName) {
    return _registry[tableName] ?? _appendOnly;
  }
}
