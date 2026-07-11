import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/analytics_repository.dart';
import '../models/analytics_models.dart';

final _analyticsRepoProvider =
    Provider<AnalyticsRepository>((ref) {
  return SupabaseAnalyticsRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

// Each section loads independently — failure in one never blocks others.

final businessHealthProvider =
    FutureProvider.autoDispose<BusinessHealth>((ref) =>
        ref.read(_analyticsRepoProvider).getBusinessHealth());

final salesAnalyticsProvider =
    FutureProvider.autoDispose<SalesAnalytics>((ref) =>
        ref.read(_analyticsRepoProvider).getSalesAnalytics());

final inventoryAnalyticsProvider =
    FutureProvider.autoDispose<InventoryAnalytics>((ref) =>
        ref.read(_analyticsRepoProvider).getInventoryAnalytics());

final purchasingAnalyticsProvider =
    FutureProvider.autoDispose<PurchasingAnalytics>((ref) =>
        ref.read(_analyticsRepoProvider).getPurchasingAnalytics());

final pricingAnalyticsProvider =
    FutureProvider.autoDispose<PricingAnalytics>((ref) =>
        ref.read(_analyticsRepoProvider).getPricingAnalytics());

final kasbonAnalyticsProvider =
    FutureProvider.autoDispose<KasbonAnalytics>((ref) =>
        ref.read(_analyticsRepoProvider).getKasbonAnalytics());

final businessInsightsProvider =
    FutureProvider.autoDispose<List<BusinessInsight>>((ref) =>
        ref.read(_analyticsRepoProvider).getBusinessInsights());
