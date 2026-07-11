import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/repositories/kasbon_explorer_repository.dart';
import '../models/customer_models.dart';

final _kasbonRepoProvider =
    Provider<KasbonExplorerRepository>((ref) {
  return SupabaseKasbonExplorerRepository(
    Supabase.instance.client,
    AppEnv.organizationId,
  );
});

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

final kasbonSummaryProvider =
    FutureProvider.autoDispose<KasbonSummary>((ref) {
  return ref.read(_kasbonRepoProvider).getKasbonSummary();
});

// ---------------------------------------------------------------------------
// Filter notifier
// ---------------------------------------------------------------------------

class CustomerFilterNotifier extends Notifier<CustomerFilter> {
  @override
  CustomerFilter build() => const CustomerFilter();

  void setSearch(String v) =>
      state = state.copyWith(search: v, page: 0);
  void setBalanceFilter(CustomerBalanceFilter v) =>
      state = state.copyWith(balanceFilter: v, page: 0);
  void setSort(CustomerSortField f) {
    if (state.sortField == f) {
      state = state.copyWith(
          sortAscending: !state.sortAscending, page: 0);
    } else {
      state = state.copyWith(
          sortField: f, sortAscending: false, page: 0);
    }
  }

  void setPage(int v) => state = state.copyWith(page: v);
  void setPageSize(int v) =>
      state = state.copyWith(pageSize: v, page: 0);
  void reset() => state = const CustomerFilter();
}

final customerFilterProvider =
    NotifierProvider<CustomerFilterNotifier, CustomerFilter>(
        CustomerFilterNotifier.new);

// ---------------------------------------------------------------------------
// Customers page
// ---------------------------------------------------------------------------

final customersPageProvider =
    FutureProvider.autoDispose<CustomerPageResult>((ref) async {
  final filter = ref.watch(customerFilterProvider);
  if (filter.search.isNotEmpty) {
    await Future.delayed(const Duration(milliseconds: 300));
    if (ref.read(customerFilterProvider).search !=
        filter.search) {
      throw Exception('debounced');
    }
  }
  return ref.read(_kasbonRepoProvider).getCustomers(filter);
});

// ---------------------------------------------------------------------------
// Detail
// ---------------------------------------------------------------------------

final customerDetailExplorerProvider =
    FutureProvider.autoDispose
        .family<CustomerExplorerDetail, String>((ref, id) {
  return ref.read(_kasbonRepoProvider).getCustomerDetail(id);
});

final customerTimelineProvider =
    FutureProvider.autoDispose
        .family<List<DebtTimelineItem>, String>((ref, id) {
  return ref
      .read(_kasbonRepoProvider)
      .getCustomerTimeline(id);
});

final debtAgingProvider =
    FutureProvider.autoDispose
        .family<List<DebtAgingBucket>, String>((ref, id) {
  return ref.read(_kasbonRepoProvider).getDebtAging(id);
});
