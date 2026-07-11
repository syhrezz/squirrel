import 'package:drift/drift.dart';

/// Products table.
///
/// Stores product master data. Price and stock changes should
/// always originate from business events (sale, restock, adjustment),
/// never from direct edits to this table during daily operations.
///
/// Conflict strategy: last-write-wins (by updated_at) on sync.
class Products extends Table {
  /// UUID v7, generated locally on device.
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// One of the fixed ProductUnit enum values stored as string.
  TextColumn get unit => text()();

  /// Only populated when unit == 'lainnya'.
  TextColumn get customUnit => text().nullable()();

  /// Latest known selling price in IDR (integer, no decimals).
  IntColumn get sellPrice => integer()();

  /// Latest known purchase price in IDR, for quick display only.
  /// Authoritative purchase history is in restock records.
  IntColumn get lastBuyPrice => integer()();

  /// Maintained automatically by sales and restock events.
  /// Not editable directly during daily operations.
  IntColumn get currentStock => integer().withDefault(const Constant(0))();

  /// Soft delete — inactive products are hidden from operational screens.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Product category — used for discovery browsing in the sales screen.
  /// One of the ProductCategory enum string values. Defaults to 'lainnya'.
  TextColumn get category =>
      text().withDefault(const Constant('lainnya'))();

  // --- Unit conversion fields ---

  /// The internal unit used to track stock.
  /// Examples: pcs, gram, ml, egg, meter
  /// This is the unit all stock numbers are stored in.
  TextColumn get inventoryUnit =>
      text().withDefault(const Constant('pcs'))();

  /// The unit used when purchasing from a supplier.
  /// Examples: Dus, Pack, Karung, Tray, Botol
  TextColumn get purchaseUnit =>
      text().withDefault(const Constant('pcs'))();

  /// How many inventory units are in ONE purchase unit.
  /// Example: 1 Dus = 40 pcs → store 40
  /// Example: 1 Karung = 5000 gram → store 5000
  IntColumn get purchaseConversion =>
      integer().withDefault(const Constant(1))();

  /// If true, operator can manually edit the price after selecting a
  /// selling option. Used for products with volatile prices (rice, sugar).
  BoolColumn get allowManualPrice =>
      boolean().withDefault(const Constant(false))();

  // --- Sync metadata ---
  IntColumn get createdAt => integer()(); // epoch milliseconds
  IntColumn get updatedAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
  TextColumn get deviceId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sales table.
///
/// Append-only. Never update or delete rows.
/// Corrections are made via separate adjustment transactions.
class Sales extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()(); // epoch ms
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text()();

  /// Sum of all sale_items.subtotal for this sale.
  IntColumn get totalAmount => integer()();

  /// Amount handed over by the customer.
  IntColumn get amountPaid => integer()();

  /// amountPaid - totalAmount. Always >= 0 at save time.
  IntColumn get changeAmount => integer()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sale items table.
///
/// Append-only. One row per product per sale.
/// selling_price is snapshotted at the time of the sale so that
/// historical transactions remain correct even if product prices change.
class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get quantity => integer()();

  /// Snapshot of the selling price at the moment of the transaction.
  IntColumn get sellingPrice => integer()();

  /// quantity × sellingPrice — stored for fast reporting.
  IntColumn get subtotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Restocks table.
///
/// Append-only. Records one shopping trip to the wholesaler.
/// Never update or delete rows. Historical trips must remain reproducible.
class Restocks extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()(); // epoch ms
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text()();

  /// Sum of all restock_items.subtotal for this trip.
  IntColumn get totalAmount => integer()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Restock items table.
///
/// Append-only. One row per product per shopping trip.
/// purchase_price is snapshotted at time of purchase so that
/// historical trips remain accurate even if prices change later.
class RestockItems extends Table {
  TextColumn get id => text()();
  TextColumn get restockId => text().references(Restocks, #id)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get quantity => integer()();

  /// Actual purchase price paid on this trip — snapshot, never changes.
  IntColumn get purchasePrice => integer()();

  /// quantity × purchasePrice — stored for fast reporting.
  IntColumn get subtotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Product selling options table.
///
/// Each product can have one or more selling options.
/// Example: Sugar → 250g @ Rp5.500, 500g @ Rp11.000, 1kg @ Rp22.000
///
/// quantity is in inventory units (e.g. grams, pcs).
/// The operator sees only display_name and selling_price — never raw numbers.
class ProductSellingOptions extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();

  /// What the operator and customer see. Example: '500 gram', '1 pcs', '1 kg'
  TextColumn get displayName => text()();

  /// How many inventory units this option represents.
  /// Example: 500 gram option → quantity = 500 (if inventory unit is gram)
  IntColumn get quantity => integer()();

  /// Price for this selling option in IDR.
  IntColumn get sellingPrice => integer()();

  /// Controls display order in the bottom sheet picker.
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0))();

  /// Soft delete — hidden options are not shown in the sales screen.
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
///
/// Stores customer identity for kasbon (credit) tracking.
/// Conflict strategy: last-write-wins (by updated_at) on sync.
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Optional — many warung customers don't share phone numbers.
  TextColumn get phone => text().nullable()();

  /// Optional free-text note about this customer.
  TextColumn get note => text().nullable()();

  /// Soft delete — deactivated customers are hidden from pickers
  /// but their debt_transactions remain intact for history.
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  // --- Sync metadata ---
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Debt transactions table.
///
/// Append-only ledger. Every kasbon event is a new row.
/// The outstanding balance is ALWAYS calculated as:
///   SUM(amount WHERE type='debt') - SUM(amount WHERE type='payment')
/// It is NEVER stored — this guarantees consistency and auditability.
///
/// type values: 'debt' | 'payment'
class DebtTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();

  /// 'debt' = money owed to shop, 'payment' = customer paying back.
  TextColumn get type => text()();

  /// Always a positive integer (IDR). Never negative.
  IntColumn get amount => integer()();

  /// Optional context note from the operator.
  TextColumn get note => text().nullable()();

  // --- Sync metadata (no updated_at — append-only) ---
  IntColumn get createdAt => integer()();
  TextColumn get createdBy => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock movements table.
///
/// Append-only ledger of every stock change.
/// Answers "why is stock at this number?" for reports.
///
/// Source types: 'sale' | 'restock' | 'adjustment'
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();

  /// Positive = stock in, negative = stock out.
  IntColumn get quantityChange => integer()();

  /// 'sale' | 'restock' | 'adjustment'
  TextColumn get sourceType => text()();

  /// UUID of the originating record (sale id, restock id, etc.)
  TextColumn get sourceId => text()();

  TextColumn get note => text().nullable()();

  // --- Sync metadata ---
  IntColumn get createdAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// =============================================================================
// SYNC INFRASTRUCTURE TABLES
// These tables belong to the sync layer, not to business features.
// Business tables are NOT responsible for sync state.
// =============================================================================

/// Sync queue table.
///
/// The authoritative list of records waiting to be pushed to the server.
/// A record enters this table when a business operation commits locally.
/// A record leaves when the server confirms receipt.
///
/// status:    'pending' | 'syncing' | 'failed'
/// operation: 'create'  | 'update'  | 'delete'
class SyncQueue extends Table {
  /// UUID v7 — unique per queue entry, not related to the business record id.
  TextColumn get id => text()();

  /// Name of the business table, e.g. 'products', 'sales', 'customers'.
  TextColumn get targetTable => text()();

  /// The UUID of the record in its business table.
  TextColumn get recordId => text()();

  /// 'create' | 'update' | 'delete'
  TextColumn get operation => text()();

  /// 'pending' | 'syncing' | 'failed'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();

  /// Last error message from the remote, if any.
  TextColumn get lastError => text().nullable()();

  IntColumn get createdAt => integer()(); // epoch ms
  IntColumn get updatedAt => integer()(); // epoch ms

  /// Epoch ms when this entry should next be retried (exponential backoff).
  /// Null = retry immediately when online.
  IntColumn get nextRetryAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync log table.
///
/// Records the outcome of every synchronization session.
/// Used for diagnostics, reporting, and debugging.
///
/// status: 'success' | 'partial' | 'failed'
class SyncLog extends Table {
  TextColumn get id => text()();
  IntColumn get startedAt => integer()();
  IntColumn get finishedAt => integer().nullable()();
  IntColumn get uploadedRecords =>
      integer().withDefault(const Constant(0))();
  IntColumn get downloadedRecords =>
      integer().withDefault(const Constant(0))();
  IntColumn get failedRecords =>
      integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().nullable()();

  /// 'success' | 'partial' | 'failed'
  TextColumn get status => text()();

  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Device info table.
///
/// Exactly ONE row per device, created on first launch.
/// Identifies this device to the sync system and stores the pull cursor.
class DeviceInfo extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();

  /// 'android' | 'ios' | 'web'
  TextColumn get platform => text()();

  TextColumn get appVersion => text()();
  IntColumn get createdAt => integer()();

  /// Updated after every successful sync session.
  IntColumn get lastSyncAt => integer().nullable()();

  /// Pull cursor — next sync will request records created after this timestamp.
  /// Null means this device has never pulled from the server.
  IntColumn get lastPullTimestamp => integer().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}
