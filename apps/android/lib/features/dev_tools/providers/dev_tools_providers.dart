import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/database_providers.dart';
import '../services/dev_tools_data_service.dart';

/// DEV ONLY — provides DevToolsDataService instance.
final devToolsDataServiceProvider = Provider<DevToolsDataService>((ref) {
  return DevToolsDataService(ref.watch(appDatabaseProvider));
});

/// DEV ONLY — provides live database statistics.
final dbStatsProvider = FutureProvider<DbStats>((ref) {
  return ref.watch(devToolsDataServiceProvider).getStats();
});

/// DEV ONLY — provides integrity check results.
final integrityCheckProvider = FutureProvider<IntegrityResult>((ref) {
  return ref.watch(devToolsDataServiceProvider).runIntegrityChecks();
});

/// DEV ONLY — provides sync metrics from sync_log table.
final syncMetricsProvider = FutureProvider<SyncMetrics>((ref) {
  return ref.watch(devToolsDataServiceProvider).getSyncMetrics();
});
