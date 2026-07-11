import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single Drift database instance for the entire app.
///
/// Each Android device has its own local SQLite database.
/// Cloud sync is handled separately by the SyncService (future phase).
@DriftDatabase(tables: [
  Products,
  StockMovements,
  Sales,
  SaleItems,
  Restocks,
  RestockItems,
  Customers,
  DebtTransactions,
  // Sync infrastructure tables
  SyncQueue,
  SyncLog,
  DeviceInfo,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 5) {
            await m.createTable(syncQueue);
            await m.createTable(syncLog);
            await m.createTable(deviceInfo);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mr_squirrel');
  }
}
