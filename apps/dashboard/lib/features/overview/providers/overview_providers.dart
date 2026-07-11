import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/models/overview_models.dart';
import '../../../core/repositories/overview_repository.dart';

final _overviewRepoProvider = Provider<OverviewRepository>((ref) {
  return SupabaseOverviewRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

/// KPI metrics — loads independently from other sections.
final dashboardMetricsProvider =
    FutureProvider<DashboardMetrics>((ref) {
  return ref.watch(_overviewRepoProvider).getDashboardMetrics();
});

/// Recent activity timeline.
final recentActivityProvider =
    FutureProvider<List<RecentActivity>>((ref) {
  return ref.watch(_overviewRepoProvider).getRecentActivity(limit: 15);
});

/// Actionable alerts.
final dashboardAlertsProvider =
    FutureProvider<List<DashboardAlert>>((ref) {
  return ref.watch(_overviewRepoProvider).getAlerts();
});

/// Top selling products today.
final topSellingProductsProvider =
    FutureProvider<List<TopSellingProduct>>((ref) {
  return ref.watch(_overviewRepoProvider).getTopSellingProducts(limit: 10);
});

/// 30-day sales trend.
final salesTrendProvider =
    FutureProvider<List<SalesTrendPoint>>((ref) {
  return ref.watch(_overviewRepoProvider).getSalesTrend(days: 30);
});
